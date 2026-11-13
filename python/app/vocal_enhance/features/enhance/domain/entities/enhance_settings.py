"""Settings of the vocal enhancement chain."""

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class EnhanceSettings:
    """Parameters of every step of the chain; a step whose amount is 0 is skipped.

    The chain runs in this order: high-pass → noise reduction → EQ → de-esser → compressor →
    loudness → limiter. Levels are in dB, frequencies in Hz, times in seconds.
    """

    high_pass_hz: float = 80.0
    """Corner of the high-pass filter that removes rumble and handling noise (0 = off)."""

    noise_reduction_db: float = 16.0
    """How much the noise between the notes is lowered (0 = off)."""

    noise_sensitivity: float = 1.5
    """Standard deviations of the noise above its mean that still count as noise."""

    noise_profile_seconds: float = 0.0
    """Leading seconds of room tone used as the noise profile (0 = find the quietest parts)."""

    mud_cut_db: float = -2.0
    """Peaking EQ at ``mud_hz``; a negative value removes boominess."""

    mud_hz: float = 250.0
    """Centre of the mud band."""

    presence_db: float = 1.5
    """Peaking EQ at ``presence_hz``; makes the words clearer."""

    presence_hz: float = 3500.0
    """Centre of the presence band."""

    air_db: float = 2.0
    """High shelf at ``air_hz``; adds air and sparkle."""

    air_hz: float = 10000.0
    """Corner of the air shelf."""

    de_ess_db: float = 6.0
    """Most the sibilance band (5-9 kHz) is lowered on "s" and "sh" (0 = off)."""

    compression_ratio: float = 3.0
    """Ratio of the compressor (1 = off)."""

    compression_threshold_db: float = -2.0
    """Threshold relative to the loudness of the recording entering the compressor."""

    compression_attack_s: float = 0.01
    """Attack time of the compressor."""

    compression_release_s: float = 0.15
    """Release time of the compressor."""

    target_lufs: float = -14.0
    """Integrated loudness of the result (streaming level)."""

    true_peak_db: float = -1.0
    """Ceiling of the limiter in dBTP."""

    limiter_release_s: float = 0.08
    """Release time of the limiter."""

    trim_silence: float = 0.0
    """1 = cut the silence before the first and after the last sung note (0 = keep it)."""

    trim_padding_s: float = 0.3
    """Silence kept before and after the singing when trimming."""
