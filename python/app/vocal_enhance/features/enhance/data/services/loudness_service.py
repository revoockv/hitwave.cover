"""Loudness (ITU-R BS.1770), true peak and noise floor."""

import math

import numpy as np
import numpy.typing as npt
from scipy import signal

from vocal_enhance.features.enhance.data.data_sources.wav_file_data_source import (
    PcmAudio,
    Samples,
)
from vocal_enhance.features.enhance.data.services.biquad_filter_service import (
    BiquadFilterService,
)
from vocal_enhance.features.enhance.domain.entities.recording_analysis import RecordingAnalysis


class LoudnessService:
    """Measures recordings; every level is in dB relative to full scale."""

    _BLOCK_SECONDS = 0.4
    _STEP_SECONDS = 0.1
    _LOUDNESS_OFFSET = -0.691
    _ABSOLUTE_GATE_LUFS = -70.0
    _RELATIVE_GATE_LU = -10.0
    _OVERSAMPLING = 4
    _PEAK_CHUNK = 1 << 14
    _PEAK_PADDING = 64
    _INTERPOLATOR_HALF_LENGTH = 10 * 4
    _INTERPOLATOR_BETA = 5.0
    _MAX_OVERSHOOT = 2.0
    """Inter-sample peaks of real audio stay well within 6 dB of the sample peaks."""
    _FULL_SCALE = 0.999
    _LEVEL_BLOCK_SECONDS = 0.05
    _NOISE_PERCENTILE = 10
    _SIGNAL_PERCENTILE = 90
    _POWER_FLOOR = 1e-20
    _PERCENT = 100.0

    def __init__(self, filters: BiquadFilterService) -> None:
        self._filters = filters
        self._fir: npt.NDArray[np.float64] | None = None

    def _interpolator(self) -> npt.NDArray[np.float64]:
        """The low-pass FIR of 4x oversampling, designed once (same as resample_poly's own)."""
        if self._fir is None:
            self._fir = np.asarray(
                signal.firwin(
                    2 * self._INTERPOLATOR_HALF_LENGTH + 1,
                    1 / self._OVERSAMPLING,
                    window=("kaiser", self._INTERPOLATOR_BETA),
                ),
                dtype=np.float64,
            )
        return self._fir

    def integrated_lufs(self, samples: Samples, sample_rate: int) -> float:
        """Gated integrated loudness in LUFS; ``-inf`` when everything is below the gate."""
        weighted = signal.sosfilt(self._filters.k_weighting(sample_rate), samples, axis=-1)
        squares = np.square(weighted)
        frames = squares.shape[1]
        block = max(1, round(self._BLOCK_SECONDS * sample_rate))
        step = max(1, round(self._STEP_SECONDS * sample_rate))
        if frames < block:
            power = squares.mean(axis=1).sum(keepdims=True)
        else:
            sums = np.concatenate(
                [np.zeros((squares.shape[0], 1)), np.cumsum(squares, axis=1)], axis=1
            )
            starts = np.arange(0, frames - block + 1, step)
            power = ((sums[:, starts + block] - sums[:, starts]) / block).sum(axis=0)
        absolute = power > self._power_of(self._ABSOLUTE_GATE_LUFS)
        if not absolute.any():
            return -math.inf
        relative_gate = self._lufs_of(float(power[absolute].mean())) + self._RELATIVE_GATE_LU
        gated = power[absolute & (power > self._power_of(relative_gate))]
        if gated.size == 0:
            return -math.inf
        return self._lufs_of(float(gated.mean()))

    def oversampled_peaks(self, samples: Samples, *, floor: float = 0.0) -> npt.NDArray[np.float64]:
        """Highest absolute value of every sample over all channels, inter-sample peaks included.

        Chunks whose inter-sample peaks cannot reach ``floor`` (their sample peak is more than
        ``_MAX_OVERSHOOT`` times lower) keep their sample peaks and are not oversampled.
        """
        sample_peaks = np.abs(samples).max(axis=0)
        frames = samples.shape[1]
        peaks = sample_peaks.copy()
        factor = self._OVERSAMPLING
        for start in range(0, frames, self._PEAK_CHUNK):
            end = min(frames, start + self._PEAK_CHUNK)
            if float(sample_peaks[start:end].max()) * self._MAX_OVERSHOOT < floor:
                continue
            left = max(0, start - self._PEAK_PADDING)
            right = min(frames, end + self._PEAK_PADDING)
            upsampled = signal.resample_poly(
                samples[:, left:right], factor, 1, axis=-1, window=self._interpolator()
            )
            low = (start - left) * factor
            high = low + (end - start) * factor
            chunk = np.abs(upsampled[:, low:high]).max(axis=0).reshape(-1, factor).max(axis=1)
            peaks[start:end] = np.maximum(chunk, sample_peaks[start:end])
        return peaks

    def true_peak(self, samples: Samples) -> float:
        """Highest inter-sample peak as a linear amplitude."""
        loudest = float(np.abs(samples).max()) if samples.size else 0.0
        return float(self.oversampled_peaks(samples, floor=loudest).max()) if samples.size else 0.0

    def measure(self, audio: PcmAudio) -> RecordingAnalysis:
        """Return the loudness, peaks, clipping and noise floor of ``audio``."""
        samples = audio.samples
        peak = self.true_peak(samples)
        clipped = float((np.abs(samples) >= self._FULL_SCALE).any(axis=0).mean()) * self._PERCENT
        noise_floor, loud = self._level_percentiles(samples, audio.sample_rate)
        return RecordingAnalysis(
            duration_s=audio.frames / audio.sample_rate,
            sample_rate=audio.sample_rate,
            channels=audio.channels,
            integrated_lufs=self.integrated_lufs(samples, audio.sample_rate),
            true_peak_db=self.to_db(peak),
            clipped_percent=clipped,
            noise_floor_db=noise_floor,
            signal_to_noise_db=loud - noise_floor,
        )

    @staticmethod
    def to_db(amplitude: float) -> float:
        """Convert a linear amplitude to dB (``-inf`` for 0)."""
        return 20 * math.log10(amplitude) if amplitude > 0 else -math.inf

    def _level_percentiles(self, samples: Samples, sample_rate: int) -> tuple[float, float]:
        block = max(1, round(self._LEVEL_BLOCK_SECONDS * sample_rate))
        blocks = samples.shape[1] // block
        if blocks == 0:
            level = 10 * math.log10(float(np.square(samples).mean()) + self._POWER_FLOOR)
            return level, level
        power = np.square(samples[:, : blocks * block]).mean(axis=0).reshape(blocks, block)
        levels = 10 * np.log10(power.mean(axis=1) + self._POWER_FLOOR)
        return (
            float(np.percentile(levels, self._NOISE_PERCENTILE)),
            float(np.percentile(levels, self._SIGNAL_PERCENTILE)),
        )

    def _power_of(self, lufs: float) -> float:
        return float(10 ** ((lufs - self._LOUDNESS_OFFSET) / 10))

    def _lufs_of(self, power: float) -> float:
        return self._LOUDNESS_OFFSET + 10 * math.log10(power)
