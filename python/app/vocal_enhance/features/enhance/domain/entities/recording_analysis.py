"""Measurements of a recording."""

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class RecordingAnalysis:
    """Levels of one recording and the problems they reveal."""

    _CLIPPED_PERCENT = 0.01
    _QUIET_PEAK_DB = -18.0
    _NOISY_SNR_DB = 30.0

    duration_s: float
    sample_rate: int
    channels: int
    integrated_lufs: float
    """Integrated loudness (ITU-R BS.1770); ``-inf`` for silence."""
    true_peak_db: float
    """Highest inter-sample peak in dBTP."""
    clipped_percent: float
    """Share of the samples at full scale, in percent."""
    noise_floor_db: float
    """Level of the quietest parts (10th percentile of 50 ms blocks), in dBFS."""
    signal_to_noise_db: float
    """Loud parts (90th percentile) above the noise floor."""

    @property
    def is_clipped(self) -> bool:
        """True when the input level was too high and the peaks were cut off."""
        return self.clipped_percent > self._CLIPPED_PERCENT

    @property
    def is_too_quiet(self) -> bool:
        """True when the input level was so low that the noise will be raised with the voice."""
        return self.true_peak_db < self._QUIET_PEAK_DB

    @property
    def is_noisy(self) -> bool:
        """True when the room noise is close to the voice."""
        return self.signal_to_noise_db < self._NOISY_SNR_DB
