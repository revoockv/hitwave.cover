"""JSON shapes of the reports, analyses, settings and progress sent to the CLI and the app."""

import math
from dataclasses import asdict
from typing import Any

from vocal_enhance.features.enhance.domain.entities.enhance_progress import EnhanceProgress
from vocal_enhance.features.enhance.domain.entities.enhance_report import EnhanceReport
from vocal_enhance.features.enhance.domain.entities.recording_analysis import RecordingAnalysis


class EnhancePayloads:
    """Maps entities to JSON-safe dicts (``-inf`` levels become ``None``)."""

    _DECIMALS = 2
    _KEPT_DECIMALS = 3
    _KEY_INPUT = "input"
    _KEY_OUTPUT = "output"
    _KEY_SETTINGS = "settings"
    _KEY_BEFORE = "before"
    _KEY_AFTER = "after"
    _KEY_SECONDS = "seconds"
    _KEY_KEPT_FROM = "kept_from_s"
    _KEY_KEPT_TO = "kept_to_s"
    _KEY_STEP = "step"
    _KEY_STEPS = "steps"
    _KEY_LABEL = "label"
    _KEY_FRACTION = "fraction"
    _KEY_CLIPPED = "is_clipped"
    _KEY_QUIET = "is_too_quiet"
    _KEY_NOISY = "is_noisy"

    @classmethod
    def report(cls, report: EnhanceReport) -> dict[str, Any]:
        """Return the report as a dict."""
        return {
            cls._KEY_INPUT: report.input_path,
            cls._KEY_OUTPUT: report.output_path,
            cls._KEY_SETTINGS: asdict(report.settings),
            cls._KEY_BEFORE: cls.analysis(report.before),
            cls._KEY_AFTER: cls.analysis(report.after),
            cls._KEY_SECONDS: round(report.seconds_spent, cls._DECIMALS),
            cls._KEY_KEPT_FROM: round(report.kept_from_s, cls._KEPT_DECIMALS),
            cls._KEY_KEPT_TO: None
            if report.kept_to_s is None
            else round(report.kept_to_s, cls._KEPT_DECIMALS),
        }

    @classmethod
    def analysis(cls, analysis: RecordingAnalysis) -> dict[str, Any]:
        """Return the measurements and the problems they show as a dict."""
        values = {name: cls._finite(value) for name, value in asdict(analysis).items()}
        values[cls._KEY_CLIPPED] = analysis.is_clipped
        values[cls._KEY_QUIET] = analysis.is_too_quiet
        values[cls._KEY_NOISY] = analysis.is_noisy
        return values

    @classmethod
    def progress(cls, progress: EnhanceProgress) -> dict[str, Any]:
        """Return the step as a dict."""
        return {
            cls._KEY_STEP: progress.step,
            cls._KEY_STEPS: progress.steps,
            cls._KEY_LABEL: progress.label,
            cls._KEY_FRACTION: round(progress.fraction, cls._DECIMALS),
        }

    @classmethod
    def _finite(cls, value: object) -> object:
        if isinstance(value, float):
            return round(value, cls._DECIMALS) if math.isfinite(value) else None
        return value
