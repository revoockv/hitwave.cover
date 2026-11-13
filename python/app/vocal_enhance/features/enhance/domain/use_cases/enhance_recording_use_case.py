"""Enhance recording use case."""

from typing import ClassVar

from vocal_enhance.core.domain.entities.result import Failure, Result
from vocal_enhance.features.enhance.domain.entities.enhance_progress import (
    EnhanceProgressListener,
)
from vocal_enhance.features.enhance.domain.entities.enhance_report import EnhanceReport
from vocal_enhance.features.enhance.domain.entities.enhance_settings import EnhanceSettings
from vocal_enhance.features.enhance.domain.repositories.enhance_repository import (
    EnhanceRepository,
)


class EnhanceRecordingUseCase:
    """Checks the settings and turns a raw vocal take into a cleaned, mastered WAV."""

    _WAV_EXTENSION = ".wav"
    _MIN_RATIO = 1.0
    _MAX_REDUCTION_DB = 40.0
    _MAX_EQ_DB = 12.0
    _MIN_TARGET_LUFS = -40.0
    _MAX_TARGET_LUFS = -6.0
    _MAX_TRUE_PEAK_DB = 0.0
    _SAME_PATH_ERROR = "The output must be a different file than the input"
    _NOT_WAV_ERROR = "The output must be a .wav file"
    _NEGATIVE_ERROR = "{name} must not be negative"
    _RATIO_ERROR = "The compression ratio must be at least 1"
    _REDUCTION_ERROR = "{name} must be at most 40 dB"
    _EQ_ERROR = "{name} must be within ±12 dB"
    _TARGET_ERROR = "The target loudness must be between -40 and -6 LUFS"
    _PEAK_ERROR = "The true peak ceiling must be below 0 dBTP"
    _NON_NEGATIVE: ClassVar[tuple[str, ...]] = (
        "high_pass_hz",
        "noise_reduction_db",
        "noise_sensitivity",
        "noise_profile_seconds",
        "de_ess_db",
        "compression_attack_s",
        "compression_release_s",
        "limiter_release_s",
        "trim_padding_s",
    )
    _REDUCTIONS: ClassVar[tuple[str, ...]] = ("noise_reduction_db", "de_ess_db")
    _EQ_GAINS: ClassVar[tuple[str, ...]] = ("mud_cut_db", "presence_db", "air_db")

    def __init__(self, repository: EnhanceRepository) -> None:
        self._repository = repository

    async def __call__(
        self,
        *,
        input_path: str,
        output_path: str,
        settings: EnhanceSettings,
        on_progress: EnhanceProgressListener | None = None,
    ) -> Result[EnhanceReport]:
        """Enhance ``input_path`` into ``output_path``; ``on_progress`` hears every step."""
        error = self._settings_error(settings)
        if error is not None:
            return Failure(error)
        if input_path == output_path:
            return Failure(self._SAME_PATH_ERROR)
        if not output_path.lower().endswith(self._WAV_EXTENSION):
            return Failure(self._NOT_WAV_ERROR)
        return await self._repository.enhance(
            input_path=input_path,
            output_path=output_path,
            settings=settings,
            on_progress=on_progress,
        )

    def _settings_error(self, settings: EnhanceSettings) -> str | None:
        for name in self._NON_NEGATIVE:
            if getattr(settings, name) < 0:
                return self._NEGATIVE_ERROR.format(name=name)
        for name in self._REDUCTIONS:
            if getattr(settings, name) > self._MAX_REDUCTION_DB:
                return self._REDUCTION_ERROR.format(name=name)
        for name in self._EQ_GAINS:
            if abs(getattr(settings, name)) > self._MAX_EQ_DB:
                return self._EQ_ERROR.format(name=name)
        if settings.compression_ratio < self._MIN_RATIO:
            return self._RATIO_ERROR
        if not self._MIN_TARGET_LUFS <= settings.target_lufs <= self._MAX_TARGET_LUFS:
            return self._TARGET_ERROR
        if settings.true_peak_db >= self._MAX_TRUE_PEAK_DB:
            return self._PEAK_ERROR
        return None
