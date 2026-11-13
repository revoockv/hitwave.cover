"""Ready-made settings of the vocal chain."""

from dataclasses import replace
from enum import StrEnum

from vocal_enhance.features.enhance.domain.entities.enhance_settings import EnhanceSettings


class EnhancePreset(StrEnum):
    """Named starting points; any setting can be changed on top of a preset."""

    NATURAL = "natural"
    """Gentle cleanup: keeps the room and the dynamics, removes rumble and steady noise."""

    STUDIO = "studio"
    """Close and polished: stronger noise reduction, more presence, tighter compression."""

    LOUDNESS_ONLY = "loudness"
    """No colouring: only the loudness and the limiter, to compare with the raw take."""

    def settings(self) -> EnhanceSettings:
        """Return the settings of this preset."""
        match self:
            case EnhancePreset.NATURAL:
                return _PresetValues.NATURAL
            case EnhancePreset.STUDIO:
                return _PresetValues.STUDIO
            case EnhancePreset.LOUDNESS_ONLY:
                return _PresetValues.LOUDNESS_ONLY


class _PresetValues:
    """Settings behind every preset."""

    NATURAL = EnhanceSettings()
    STUDIO = replace(
        NATURAL,
        noise_reduction_db=22.0,
        mud_cut_db=-3.0,
        presence_db=2.5,
        air_db=3.0,
        de_ess_db=8.0,
        compression_ratio=4.0,
        compression_threshold_db=-4.0,
    )
    LOUDNESS_ONLY = replace(
        NATURAL,
        high_pass_hz=0.0,
        noise_reduction_db=0.0,
        mud_cut_db=0.0,
        presence_db=0.0,
        air_db=0.0,
        de_ess_db=0.0,
        compression_ratio=1.0,
    )
