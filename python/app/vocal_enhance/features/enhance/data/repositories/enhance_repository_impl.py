"""Enhance repository implementation."""

import asyncio
import logging
import time
from collections.abc import Callable
from dataclasses import dataclass

from vocal_enhance.core.domain.entities.result import Failure, Result, Success
from vocal_enhance.features.enhance.data.data_sources.wav_file_data_source import (
    PcmAudio,
    Samples,
    WavFileDataSource,
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
from vocal_enhance.features.enhance.domain.entities.enhance_progress import (
    EnhanceProgress,
    EnhanceProgressListener,
)
from vocal_enhance.features.enhance.domain.entities.enhance_report import EnhanceReport
from vocal_enhance.features.enhance.domain.entities.enhance_settings import EnhanceSettings
from vocal_enhance.features.enhance.domain.entities.recording_analysis import RecordingAnalysis
from vocal_enhance.features.enhance.domain.repositories.enhance_repository import (
    EnhanceRepository,
)

type _Step = Callable[[Samples, int, EnhanceSettings], Samples]


@dataclass(frozen=True, slots=True)
class _ChainStep:
    label: str
    run: _Step


class EnhanceRepositoryImpl(EnhanceRepository):
    """Runs the vocal chain with numpy/scipy services; converts exceptions to ``Failure``."""

    _MAX_GAIN_DB = 30.0
    _LOUDNESS_PASSES = 4
    _LOUDNESS_TOLERANCE_LU = 0.2
    _MAX_EXTRA_DB = 6.0

    def __init__(
        self,
        *,
        wav_files: WavFileDataSource,
        filters: BiquadFilterService,
        noise_reduction: NoiseReductionService,
        dynamics: DynamicsService,
        loudness: LoudnessService,
        silence_trim: SilenceTrimService,
        logger: logging.Logger,
    ) -> None:
        self._wav_files = wav_files
        self._filters = filters
        self._noise_reduction = noise_reduction
        self._dynamics = dynamics
        self._loudness = loudness
        self._silence_trim = silence_trim
        self._logger = logger
        self._chain = [
            _ChainStep("Removing rumble", self._high_pass),
            _ChainStep("Reducing noise", self._reduce_noise),
            _ChainStep("Shaping the tone", self._equalize),
            _ChainStep("Taming sibilance", self._de_ess),
            _ChainStep("Evening out the dynamics", self._compress),
            _ChainStep("Setting the loudness", self._normalize),
            _ChainStep("Limiting the peaks", self._limit),
        ]

    async def enhance(
        self,
        *,
        input_path: str,
        output_path: str,
        settings: EnhanceSettings,
        on_progress: EnhanceProgressListener | None,
    ) -> Result[EnhanceReport]:
        """Read, process and write in a worker thread; report every step to ``on_progress``."""
        try:
            report = await asyncio.to_thread(
                self._enhance, input_path, output_path, settings, on_progress
            )
        except Exception as e:
            self._logger.error("Enhance: failure — %s: %s", input_path, e)
            return Failure(str(e))
        self._logger.info(
            "Enhance: success — %s → %s (%.1f → %.1f LUFS, %.1fs)",
            input_path,
            output_path,
            report.before.integrated_lufs,
            report.after.integrated_lufs,
            report.seconds_spent,
        )
        return Success(report)

    async def analyze(self, *, input_path: str) -> Result[RecordingAnalysis]:
        """Measure the file in a worker thread."""
        try:
            analysis = await asyncio.to_thread(
                lambda: self._loudness.measure(self._wav_files.read(input_path))
            )
        except Exception as e:
            self._logger.error("Analyze: failure — %s: %s", input_path, e)
            return Failure(str(e))
        self._logger.info(
            "Analyze: success — %s: %.1f LUFS, peak %.1f dBTP",
            input_path,
            analysis.integrated_lufs,
            analysis.true_peak_db,
        )
        return Success(analysis)

    def _enhance(
        self,
        input_path: str,
        output_path: str,
        settings: EnhanceSettings,
        on_progress: EnhanceProgressListener | None,
    ) -> EnhanceReport:
        started = time.perf_counter()
        steps = len(self._chain) + 3

        def report(step: int, label: str) -> None:
            if on_progress is not None:
                on_progress(EnhanceProgress(step=step, steps=steps, label=label))

        report(1, "Reading the recording")
        audio = self._wav_files.read(input_path)
        before = self._loudness.measure(audio)
        samples = audio.samples
        for number, chain_step in enumerate(self._chain, start=2):
            report(number, chain_step.label)
            samples = chain_step.run(samples, audio.sample_rate, settings)
        report(steps - 1, "Trimming the silence")
        start, end = 0, samples.shape[1]
        if settings.trim_silence > 0:
            start, end = self._silence_trim.kept_range(
                samples, audio.sample_rate, padding_s=settings.trim_padding_s
            )
            samples = self._silence_trim.cut(samples, audio.sample_rate, start=start, end=end)
        report(steps, "Writing the result")
        result = PcmAudio(samples=samples, sample_rate=audio.sample_rate)
        self._wav_files.write(output_path, result)
        return EnhanceReport(
            input_path=input_path,
            output_path=output_path,
            settings=settings,
            before=before,
            after=self._loudness.measure(result),
            seconds_spent=time.perf_counter() - started,
            kept_from_s=start / audio.sample_rate,
            kept_to_s=end / audio.sample_rate,
        )

    def _high_pass(self, samples: Samples, rate: int, settings: EnhanceSettings) -> Samples:
        if settings.high_pass_hz <= 0:
            return samples
        return self._filters.high_pass(samples, rate, corner_hz=settings.high_pass_hz)

    def _reduce_noise(self, samples: Samples, rate: int, settings: EnhanceSettings) -> Samples:
        return self._noise_reduction.reduce(
            samples,
            rate,
            reduction_db=settings.noise_reduction_db,
            sensitivity=settings.noise_sensitivity,
            profile_seconds=settings.noise_profile_seconds,
        )

    def _equalize(self, samples: Samples, rate: int, settings: EnhanceSettings) -> Samples:
        return self._filters.equalize(
            samples,
            rate,
            bells=[
                (settings.mud_hz, settings.mud_cut_db),
                (settings.presence_hz, settings.presence_db),
            ],
            high_shelf=(settings.air_hz, settings.air_db),
        )

    def _de_ess(self, samples: Samples, rate: int, settings: EnhanceSettings) -> Samples:
        return self._dynamics.de_ess(samples, rate, max_reduction_db=settings.de_ess_db)

    def _compress(self, samples: Samples, rate: int, settings: EnhanceSettings) -> Samples:
        return self._dynamics.compress(
            samples,
            rate,
            ratio=settings.compression_ratio,
            threshold_db=settings.compression_threshold_db,
            attack_s=settings.compression_attack_s,
            release_s=settings.compression_release_s,
        )

    def _normalize(self, samples: Samples, rate: int, settings: EnhanceSettings) -> Samples:
        loudness = self._loudness.integrated_lufs(samples, rate)
        if loudness == -float("inf"):
            return samples
        gain_db = min(settings.target_lufs - loudness, self._MAX_GAIN_DB)
        return samples * 10 ** (gain_db / 20)

    def _limit(self, samples: Samples, rate: int, settings: EnhanceSettings) -> Samples:
        """Limit, then make up the loudness the limiter took away (a few passes)."""
        extra_db = 0.0
        limited = samples
        for _ in range(self._LOUDNESS_PASSES):
            limited = self._dynamics.limit(
                samples * 10 ** (extra_db / 20),
                rate,
                ceiling_db=settings.true_peak_db,
                release_s=settings.limiter_release_s,
            )
            shortfall = settings.target_lufs - self._loudness.integrated_lufs(limited, rate)
            if not shortfall > self._LOUDNESS_TOLERANCE_LU or extra_db >= self._MAX_EXTRA_DB:
                break
            extra_db = min(extra_db + shortfall, self._MAX_EXTRA_DB)
        return limited
