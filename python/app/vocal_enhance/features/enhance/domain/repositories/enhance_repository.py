"""Enhance repository contract."""

from abc import ABC, abstractmethod

from vocal_enhance.core.domain.entities.result import Result
from vocal_enhance.features.enhance.domain.entities.enhance_progress import (
    EnhanceProgressListener,
)
from vocal_enhance.features.enhance.domain.entities.enhance_report import EnhanceReport
from vocal_enhance.features.enhance.domain.entities.enhance_settings import EnhanceSettings
from vocal_enhance.features.enhance.domain.entities.recording_analysis import RecordingAnalysis


class EnhanceRepository(ABC):
    """Measures recordings and runs the vocal chain over WAV files."""

    @abstractmethod
    async def enhance(
        self,
        *,
        input_path: str,
        output_path: str,
        settings: EnhanceSettings,
        on_progress: EnhanceProgressListener | None,
    ) -> Result[EnhanceReport]:
        """Process ``input_path`` with ``settings`` and write a 24-bit WAV to ``output_path``."""

    @abstractmethod
    async def analyze(self, *, input_path: str) -> Result[RecordingAnalysis]:
        """Measure the levels of a WAV file."""
