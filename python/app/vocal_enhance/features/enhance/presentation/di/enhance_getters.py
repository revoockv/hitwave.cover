"""Getters through which the enhance presentation layer reaches its use cases.

Presentation code imports these functions instead of touching the container or the domain
use case modules directly.
"""

from vocal_enhance.core.presentation.di.container import container
from vocal_enhance.features.enhance.domain.use_cases.analyze_recording_use_case import (
    AnalyzeRecordingUseCase,
)
from vocal_enhance.features.enhance.domain.use_cases.enhance_recording_use_case import (
    EnhanceRecordingUseCase,
)


def enhance_recording_use_case() -> EnhanceRecordingUseCase:
    """Return the registered ``EnhanceRecordingUseCase``."""
    return container.get(EnhanceRecordingUseCase)


def analyze_recording_use_case() -> AnalyzeRecordingUseCase:
    """Return the registered ``AnalyzeRecordingUseCase``."""
    return container.get(AnalyzeRecordingUseCase)
