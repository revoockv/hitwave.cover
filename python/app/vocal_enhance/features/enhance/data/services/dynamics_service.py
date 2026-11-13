"""De-esser, compressor and true-peak limiter."""

import math

import numpy as np
import numpy.typing as npt
from numpy.lib.stride_tricks import sliding_window_view

from vocal_enhance.features.enhance.data.data_sources.wav_file_data_source import Samples
from vocal_enhance.features.enhance.data.services.biquad_filter_service import (
    BiquadFilterService,
)
from vocal_enhance.features.enhance.data.services.loudness_service import LoudnessService

type Floats = npt.NDArray[np.float64]


class DynamicsService:
    """Level-dependent gain: gains are computed on short frames, smoothed and interpolated."""

    _POWER_FLOOR = 1e-20
    _COMPRESSOR_FRAME_S = 0.005
    _KNEE_DB = 6.0
    _DE_ESS_FRAME_S = 0.0025
    _DE_ESS_LOW_HZ = 5000.0
    _DE_ESS_HIGH_HZ = 9000.0
    _DE_ESS_ABOVE_VOICE_DB = 10.0
    """The band counts as sibilant when it is within this many dB of the whole signal."""
    _DE_ESS_GATE_DB = -60.0
    _DE_ESS_ATTACK_S = 0.001
    _DE_ESS_RELEASE_S = 0.04
    _LIMITER_BLOCK = 64
    _LIMITER_LOOKAHEAD_S = 0.005
    _MIN_TIME_S = 1e-6

    def __init__(self, *, filters: BiquadFilterService, loudness: LoudnessService) -> None:
        self._filters = filters
        self._loudness = loudness

    def de_ess(self, samples: Samples, sample_rate: int, *, max_reduction_db: float) -> Samples:
        """Lower the 5-9 kHz band by up to ``max_reduction_db`` while it dominates the voice."""
        if max_reduction_db <= 0:
            return samples
        band = self._filters.band(
            samples, sample_rate, low_hz=self._DE_ESS_LOW_HZ, high_hz=self._DE_ESS_HIGH_HZ
        )
        frame = max(1, round(self._DE_ESS_FRAME_S * sample_rate))
        band_db = self._frame_levels_db(band, frame)
        full_db = self._frame_levels_db(samples, frame)
        excess = band_db - (full_db - self._DE_ESS_ABOVE_VOICE_DB)
        reduction = np.where(
            band_db > self._DE_ESS_GATE_DB, np.clip(excess, 0, max_reduction_db), 0
        )
        smoothed = self._smooth(
            -reduction,
            frame_s=frame / sample_rate,
            attack_s=self._DE_ESS_ATTACK_S,
            release_s=self._DE_ESS_RELEASE_S,
        )
        gain = self._per_sample(10 ** (smoothed / 20), frame, samples.shape[1])
        return np.asarray(samples - band * (1 - gain), dtype=np.float64)

    def compress(
        self,
        samples: Samples,
        sample_rate: int,
        *,
        ratio: float,
        threshold_db: float,
        attack_s: float,
        release_s: float,
    ) -> Samples:
        """Compress above ``threshold_db`` (relative to the loudness of ``samples``)."""
        if ratio <= 1:
            return samples
        loudness = self._loudness.integrated_lufs(samples, sample_rate)
        if math.isinf(loudness):
            return samples
        threshold = loudness + threshold_db
        frame = max(1, round(self._COMPRESSOR_FRAME_S * sample_rate))
        over = self._frame_levels_db(samples, frame) - threshold
        half = self._KNEE_DB / 2
        slope = 1 / ratio - 1
        reduction = np.where(
            over <= -half,
            0.0,
            np.where(
                over >= half, slope * over, slope * np.square(over + half) / (2 * self._KNEE_DB)
            ),
        )
        smoothed = self._smooth(
            reduction, frame_s=frame / sample_rate, attack_s=attack_s, release_s=release_s
        )
        gain = self._per_sample(10 ** (smoothed / 20), frame, samples.shape[1])
        return np.asarray(samples * gain, dtype=np.float64)

    def limit(
        self, samples: Samples, sample_rate: int, *, ceiling_db: float, release_s: float
    ) -> Samples:
        """Keep the inter-sample peaks under ``ceiling_db`` with a 5 ms look-ahead."""
        ceiling = 10 ** (ceiling_db / 20)
        peaks = self._loudness.oversampled_peaks(samples, floor=ceiling)
        block = self._LIMITER_BLOCK
        blocks = -(-peaks.size // block)
        padded = np.zeros(blocks * block)
        padded[: peaks.size] = peaks
        block_peaks = padded.reshape(blocks, block).max(axis=1)
        needed = np.minimum(1.0, ceiling / np.maximum(block_peaks, self._POWER_FLOOR))
        ahead = max(1, math.ceil(self._LIMITER_LOOKAHEAD_S * sample_rate / block))
        # earliest[i] = min(needed[i … i + ahead]): the gain is down `ahead` blocks before a peak.
        earliest = sliding_window_view(
            np.pad(needed, (0, ahead), constant_values=1.0), ahead + 1
        ).min(axis=1)
        recovery = 1 - math.exp(-block / (sample_rate * max(release_s, self._MIN_TIME_S)))
        held = np.empty_like(earliest)
        current = 1.0
        for index, target in enumerate(earliest.tolist()):
            current = (
                target if target < current else min(target, current + (1 - current) * recovery)
            )
            held[index] = current
        # ramped[i] = mean(held[i - ahead … i]); every one of those is ≤ needed[i], so the
        # ramp into a peak never lets it through.
        ramped = sliding_window_view(np.pad(held, (ahead, 0), mode="edge"), ahead + 1).mean(axis=1)
        ramped = np.minimum(ramped, needed)
        per_block = np.repeat(ramped, block)[: samples.shape[1]]
        centres = (np.arange(blocks) + 0.5) * block
        smooth = np.interp(np.arange(samples.shape[1]), centres, ramped)
        gain = np.minimum(per_block, smooth)
        return np.clip(samples * gain, -ceiling, ceiling)

    def _frame_levels_db(self, samples: Samples, frame: int) -> Floats:
        frames = -(-samples.shape[1] // frame)
        padded = np.zeros((samples.shape[0], frames * frame))
        padded[:, : samples.shape[1]] = samples
        power = np.square(padded).mean(axis=0).reshape(frames, frame).mean(axis=1)
        return np.asarray(10 * np.log10(power + self._POWER_FLOOR), dtype=np.float64)

    def _smooth(
        self, gain_db: Floats, *, frame_s: float, attack_s: float, release_s: float
    ) -> Floats:
        attack = math.exp(-frame_s / attack_s) if attack_s > 0 else 0.0
        release = math.exp(-frame_s / release_s) if release_s > 0 else 0.0
        smoothed = np.empty_like(gain_db)
        current = 0.0
        for index, target in enumerate(gain_db.tolist()):
            coefficient = attack if target < current else release
            current = coefficient * current + (1 - coefficient) * target
            smoothed[index] = current
        return smoothed

    def _per_sample(self, frame_gain: Floats, frame: int, length: int) -> Floats:
        centres = (np.arange(frame_gain.size) + 0.5) * frame
        return np.asarray(np.interp(np.arange(length), centres, frame_gain), dtype=np.float64)
