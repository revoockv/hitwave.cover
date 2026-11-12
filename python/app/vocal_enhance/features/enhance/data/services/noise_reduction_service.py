"""Spectral-gate noise reduction with a learned noise profile."""

import numpy as np
import numpy.typing as npt
from numpy.lib.stride_tricks import sliding_window_view
from scipy import ndimage, signal

from vocal_enhance.features.enhance.data.data_sources.wav_file_data_source import Samples

type Spectrum = npt.NDArray[np.complex128]
type Floats = npt.NDArray[np.float64]


class NoiseReductionService:
    """Lowers every time-frequency bin that is no louder than the room noise.

    The noise profile (median and spread of the noise level in every frequency bin) comes from
    the leading room tone when the caller says how long it is, otherwise from the quietest 3 %
    of the recording; digital silence is never part of it. A bin above the profile passes, a
    bin inside it is lowered by the reduction amount, with a soft 6 dB transition. The gain
    mask is smoothed over time and frequency so that steady tones stay steady and no "musical
    noise" chirps appear.

    The STFT is processed in batches of frames, so memory stays small for long takes.
    """

    _FFT_SIZE_HIGH_RATE = 2048
    _FFT_SIZE_LOW_RATE = 1024
    _HIGH_RATE = 32000
    _HOP_DIVISOR = 4
    _BATCH_FRAMES = 512
    _SMOOTH_FRAMES = 5
    _SMOOTH_BINS = 3
    _TRANSITION_DB = 6.0
    _QUIET_SHARE = 0.03
    _SILENCE_DB = -100.0
    _QUARTILE_LOW = 25
    _QUARTILE_HIGH = 75
    _IQR_TO_SPREAD = 1.349
    _MIN_PROFILE_FRAMES = 8
    _MAX_PROFILE_FRAMES = 4000
    _EPSILON = 1e-12

    def reduce(
        self,
        samples: Samples,
        sample_rate: int,
        *,
        reduction_db: float,
        sensitivity: float,
        profile_seconds: float,
    ) -> Samples:
        """Return ``samples`` with the steady noise lowered by ``reduction_db``."""
        if reduction_db <= 0:
            return samples
        size = (
            self._FFT_SIZE_HIGH_RATE if sample_rate >= self._HIGH_RATE else self._FFT_SIZE_LOW_RATE
        )
        profile_frames = round(profile_seconds * sample_rate)
        return np.stack(
            [
                self._reduce_channel(
                    channel,
                    size=size,
                    reduction_db=reduction_db,
                    sensitivity=sensitivity,
                    profile_frames=profile_frames,
                )
                for channel in samples
            ]
        )

    def _reduce_channel(
        self,
        channel: Floats,
        *,
        size: int,
        reduction_db: float,
        sensitivity: float,
        profile_frames: int,
    ) -> Floats:
        hop = size // self._HOP_DIVISOR
        length = channel.size
        tail = size + (-(length + size) % hop)
        padded = np.concatenate([np.zeros(size), channel, np.zeros(tail)])
        window = signal.get_window("hann", size)
        frames = sliding_window_view(padded, size)[::hop]
        count = frames.shape[0]

        mean_db, spread_db = self._noise_profile(
            padded, frames, window, size=size, length=length, profile_frames=profile_frames
        )
        threshold = mean_db + sensitivity * spread_db

        output = np.zeros_like(padded)
        context = self._SMOOTH_FRAMES
        for first in range(0, count, self._BATCH_FRAMES):
            last = min(count, first + self._BATCH_FRAMES)
            low = max(0, first - context)
            high = min(count, last + context)
            spectra = np.fft.rfft(frames[low:high] * window, axis=1)
            level_db = 20 * np.log10(np.abs(spectra) + self._EPSILON)
            keep = np.clip((level_db - threshold) / self._TRANSITION_DB + 0.5, 0.0, 1.0)
            keep = ndimage.uniform_filter(
                keep, size=(self._SMOOTH_FRAMES, self._SMOOTH_BINS), mode="nearest"
            )
            gain = 10 ** (-(1.0 - keep) * reduction_db / 20)
            cleaned = np.fft.irfft(spectra * gain, n=size, axis=1)[first - low : last - low]
            self._overlap_add(output, cleaned * window, first=first, hop=hop)

        return output[size : size + length] / self._window_weight(window, hop, length)

    def _noise_profile(
        self,
        padded: Floats,
        frames: Floats,
        window: Floats,
        *,
        size: int,
        length: int,
        profile_frames: int,
    ) -> tuple[Floats, Floats]:
        hop = size // self._HOP_DIVISOR
        starts = np.arange(frames.shape[0]) * hop
        squares = np.concatenate([[0.0], np.cumsum(np.square(padded))])
        energy = squares[starts + size] - squares[starts]
        # Digital silence (the recorder starting up) is no room noise: it would drag the profile
        # down and widen its spread until the gate lowers the voice instead of the noise.
        audible = energy > size * 10 ** (self._SILENCE_DB / 10)
        inside = (starts >= size) & (starts + size <= size + length) & audible

        chosen = np.flatnonzero(inside & (starts + size <= size + profile_frames))
        all_inside = np.flatnonzero(inside)
        if chosen.size < self._MIN_PROFILE_FRAMES or (
            all_inside.size and energy[chosen].mean() > np.median(energy[all_inside])
        ):
            chosen = self._quietest(energy, all_inside)
        if chosen.size == 0:
            chosen = np.arange(frames.shape[0])
        if chosen.size > self._MAX_PROFILE_FRAMES:
            chosen = chosen[np.linspace(0, chosen.size - 1, self._MAX_PROFILE_FRAMES).astype(int)]

        level_db = 20 * np.log10(
            np.abs(np.fft.rfft(frames[chosen] * window, axis=1)) + self._EPSILON
        )
        # Median and quartile spread: a few loud frames among the quiet ones do not move them.
        low, middle, high = np.percentile(
            level_db, [self._QUARTILE_LOW, 50, self._QUARTILE_HIGH], axis=0
        )
        return middle, (high - low) / self._IQR_TO_SPREAD

    def _quietest(self, energy: Floats, candidates: npt.NDArray[np.intp]) -> npt.NDArray[np.intp]:
        if candidates.size == 0:
            return candidates
        count = max(self._MIN_PROFILE_FRAMES, int(candidates.size * self._QUIET_SHARE))
        order = np.argsort(energy[candidates], kind="stable")[:count]
        return np.sort(candidates[order])

    def _overlap_add(self, output: Floats, frames: Floats, *, first: int, hop: int) -> None:
        """Add windowed frames ``first, first + 1, …`` into ``output``.

        Frames whose numbers differ by ``_HOP_DIVISOR`` lie end to end, so each of the
        ``_HOP_DIVISOR`` groups is added as one contiguous slice.
        """
        for phase in range(self._HOP_DIVISOR):
            offset = (phase - first) % self._HOP_DIVISOR
            group = frames[offset :: self._HOP_DIVISOR]
            if group.shape[0] == 0:
                continue
            start = (first + offset) * hop
            flat = group.reshape(-1)
            output[start : start + flat.size] += flat

    def _window_weight(self, window: Floats, hop: int, length: int) -> Floats:
        """Sum of the squared windows over every output sample (analysis x synthesis)."""
        folded = np.square(window).reshape(self._HOP_DIVISOR, hop).sum(axis=0)
        return np.asarray(folded[np.arange(length) % hop], dtype=np.float64)
