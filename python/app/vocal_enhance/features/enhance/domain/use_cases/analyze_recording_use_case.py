"""Analyze recording use case."""

from vocal_enhance.core.domain.entities.result import Result
from vocal_enhance.features.enhance.domain.entities.recording_analysis import RecordingAnalysis
from vocal_enhance.features.enhance.domain.repositories.enhance_repository import (
    EnhanceRepository,
)


class AnalyzeRecordingUseCase:
    """Measures a take so the user learns whether it is clipped, too quiet or noisy."""

    def __init__(self, repository: EnhanceRepository) -> None:
        self._repository = repository

    async def __call__(self, *, input_path: str) -> Result[RecordingAnalysis]:
        """Return the levels of the WAV file at ``input_path``."""
        return await self._repository.analyze(input_path=input_path)
