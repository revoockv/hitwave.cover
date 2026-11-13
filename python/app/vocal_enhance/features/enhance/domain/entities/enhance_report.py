"""Result of enhancing one recording."""

from dataclasses import dataclass

from vocal_enhance.features.enhance.domain.entities.enhance_settings import EnhanceSettings
from vocal_enhance.features.enhance.domain.entities.recording_analysis import RecordingAnalysis


@dataclass(frozen=True, slots=True)
class EnhanceReport:
    """Where the enhanced file is, the settings used and the levels before and after."""

    input_path: str
    output_path: str
    settings: EnhanceSettings
    before: RecordingAnalysis
    after: RecordingAnalysis
    seconds_spent: float
    kept_from_s: float = 0.0
    """Where the enhanced file starts in the raw take (silence trimmed before it)."""
    kept_to_s: float | None = None
    """Where the enhanced file ends in the raw take; ``None`` = the end of the take."""
