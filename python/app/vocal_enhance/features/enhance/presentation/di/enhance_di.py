"""DI registration for the enhance feature."""

import logging

from vocal_enhance.core.presentation.di.container import Container
from vocal_enhance.features.enhance.data.data_sources.wav_file_data_source import (
    LocalWavFileDataSource,
    WavFileDataSource,
)
from vocal_enhance.features.enhance.data.repositories.enhance_repository_impl import (
    EnhanceRepositoryImpl,
)
from vocal_enhance.features.enhance.data.services.biquad_filter_service import (
    BiquadFilterService,
)
from vocal_enhance.features.enhance.data.services.dynamics_service import DynamicsService
from vocal_enhance.features.enhance.data.services.loudness_service import LoudnessService
from vocal_enhance.features.enhance.data.services.noise_reduction_service import (
    NoiseReductionService,
)
from vocal_enhance.features.enhance.data.services.silence_trim_service import SilenceTrimService
from vocal_enhance.features.enhance.domain.repositories.enhance_repository import (
    EnhanceRepository,
)
from vocal_enhance.features.enhance.domain.use_cases.analyze_recording_use_case import (
    AnalyzeRecordingUseCase,
)
from vocal_enhance.features.enhance.domain.use_cases.enhance_recording_use_case import (
    EnhanceRecordingUseCase,
)


def register_enhance(container: Container) -> None:
    """Register data sources, repositories and use cases of the enhance feature.

    Order: data sources → services → repositories (by domain interface) → use cases.
    """
    container.register_singleton(WavFileDataSource, LocalWavFileDataSource())
    filters = BiquadFilterService()
    loudness = LoudnessService(filters)
    container.register_singleton(
        EnhanceRepository,
        EnhanceRepositoryImpl(
            wav_files=container.get(WavFileDataSource),
            filters=filters,
            noise_reduction=NoiseReductionService(),
            dynamics=DynamicsService(filters=filters, loudness=loudness),
            loudness=loudness,
            silence_trim=SilenceTrimService(),
            logger=container.get(logging.Logger),
        ),
    )
    repository = container.get(EnhanceRepository)
    container.register_singleton(EnhanceRecordingUseCase, EnhanceRecordingUseCase(repository))
    container.register_singleton(AnalyzeRecordingUseCase, AnalyzeRecordingUseCase(repository))
