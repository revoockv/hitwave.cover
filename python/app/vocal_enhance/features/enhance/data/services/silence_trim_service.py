"""Finds where the singing starts and ends, to cut the silence around it."""

import numpy as np

from vocal_enhance.features.enhance.data.data_sources.wav_file_data_source import Samples


class SilenceTrimService:
    """Keeps the part between the first and the last loud block, plus a little padding.

    A 50 ms block is loud when it is 10 dB above the noise floor (10th percentile of the blocks)
    and no more than 45 dB below the loudest blocks (95th percentile); the second rule keeps
    breaths and reverb tails of a clean take that has almost no noise.
    """

    _BLOCK_SECONDS = 0.05
    _FADE_SECONDS = 0.02
    _MIN_BLOCKS = 3
    _NOISE_PERCENTILE = 10
    _LOUD_PERCENTILE = 95
    _ABOVE_NOISE_DB = 10.0
    _BELOW_LOUD_DB = 45.0
    _POWER_FLOOR = 1e-20

    def kept_range(
        self, samples: Samples, sample_rate: int, *, padding_s: float
    ) -> tuple[int, int]:
        """Return ``(start, end)`` sample indexes of the part to keep (the whole take if unsure)."""
        frames = samples.shape[1]
        block = max(1, round(self._BLOCK_SECONDS * sample_rate))
        blocks = frames // block
        if blocks < self._MIN_BLOCKS:
            return 0, frames
        power = np.square(samples[:, : blocks * block]).mean(axis=0).reshape(blocks, block)
        levels = 10 * np.log10(power.mean(axis=1) + self._POWER_FLOOR)
        threshold = max(
            float(np.percentile(levels, self._NOISE_PERCENTILE)) + self._ABOVE_NOISE_DB,
            float(np.percentile(levels, self._LOUD_PERCENTILE)) - self._BELOW_LOUD_DB,
        )
        loud = np.flatnonzero(levels > threshold)
        if loud.size == 0:
            return 0, frames
        padding = round(padding_s * sample_rate)
        start = max(0, int(loud[0]) * block - padding)
        end = min(frames, (int(loud[-1]) + 1) * block + padding)
        return start, end

    def cut(self, samples: Samples, sample_rate: int, *, start: int, end: int) -> Samples:
        """Return ``samples[start:end]`` with short fades where it was cut."""
        kept = samples[:, start:end].copy()
        fade = min(round(self._FADE_SECONDS * sample_rate), kept.shape[1] // 2)
        if fade > 0:
            ramp = np.linspace(0.0, 1.0, fade)
            if start > 0:
                kept[:, :fade] *= ramp
            if end < samples.shape[1]:
                kept[:, -fade:] *= ramp[::-1]
        return kept
