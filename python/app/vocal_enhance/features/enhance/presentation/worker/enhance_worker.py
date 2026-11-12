"""Message worker that serves the app (Dart ↔ Python bridge) or any other byte channel."""

import asyncio
import json
import queue
import threading
from collections.abc import Callable
from dataclasses import asdict
from typing import Any

from vocal_enhance.core.domain.entities.result import Failure, Success
from vocal_enhance.features.enhance.domain.entities.enhance_preset import EnhancePreset
from vocal_enhance.features.enhance.domain.entities.enhance_progress import EnhanceProgress
from vocal_enhance.features.enhance.presentation.di.enhance_getters import (
    analyze_recording_use_case,
    enhance_recording_use_case,
)
from vocal_enhance.features.enhance.presentation.schemas.enhance_payloads import EnhancePayloads
from vocal_enhance.features.enhance.presentation.schemas.settings_overrides import (
    SettingsOverrides,
)

type Send = Callable[[bytes], None]
"""Delivers one UTF-8 JSON event to the other side."""


class WorkerProtocol:
    """Names used in the JSON messages. Requests carry ``op``, events carry ``event``.

    Requests::

        {"op": "ping"}
        {"op": "presets"}
        {"op": "analyze", "id": "…", "input": "/…/take.wav"}
        {"op": "enhance", "id": "…", "input": "/…/take.wav", "output": "/…/take_enhanced.wav",
         "preset": "natural", "settings": {"noise_profile_seconds": 1.5}}

    Events::

        {"event": "ready", "protocol": 1}
        {"event": "presets", "presets": {"natural": {…settings…}, …}}
        {"event": "progress", "id": "…", "step": 3, "steps": 10, "label": "…", "fraction": 0.22}
        {"event": "analysis", "id": "…", "analysis": {…}}
        {"event": "done", "id": "…", "report": {…}}
        {"event": "error", "id": "…", "message": "…"}
    """

    VERSION = 1
    OP = "op"
    EVENT = "event"
    ID = "id"
    INPUT = "input"
    OUTPUT = "output"
    PRESET = "preset"
    SETTINGS = "settings"
    MESSAGE = "message"
    PROTOCOL = "protocol"
    PRESETS = "presets"
    ANALYSIS = "analysis"
    REPORT = "report"
    PING = "ping"
    ANALYZE = "analyze"
    ENHANCE = "enhance"
    READY = "ready"
    PROGRESS = "progress"
    DONE = "done"
    ERROR = "error"
    DEFAULT_PRESET = EnhancePreset.NATURAL.value


class EnhanceWorker:
    """Takes requests from any thread and runs them one at a time on its own thread."""

    _ENCODING = "utf-8"
    _THREAD_NAME = "vocal-enhance-worker"
    _NOT_JSON = "The request is not a JSON object"
    _UNKNOWN_OP = "Unknown op {op!r}"
    _MISSING_FIELD = "The request needs a string {name!r}"
    _NOT_AN_OBJECT = "{name!r} must be an object"

    def __init__(self, send: Send) -> None:
        self._send = send
        self._requests: queue.Queue[dict[str, Any] | None] = queue.Queue()
        self._thread = threading.Thread(target=self._serve, name=self._THREAD_NAME, daemon=True)

    def start(self) -> None:
        """Start the processing thread and announce that the worker is ready."""
        self._thread.start()
        self._emit(
            {
                WorkerProtocol.EVENT: WorkerProtocol.READY,
                WorkerProtocol.PROTOCOL: WorkerProtocol.VERSION,
            }
        )

    def stop(self) -> None:
        """Finish the queued requests and stop the processing thread."""
        self._requests.put(None)
        self._thread.join()

    def handle(self, payload: bytes) -> None:
        """Queue one request; safe to call from the bridge's thread."""
        try:
            request = json.loads(payload.decode(self._ENCODING))
        except (UnicodeDecodeError, json.JSONDecodeError):
            request = None
        if not isinstance(request, dict):
            self._error(None, self._NOT_JSON)
            return
        self._requests.put(request)

    def _serve(self) -> None:
        while (request := self._requests.get()) is not None:
            asyncio.run(self._dispatch(request))

    async def _dispatch(self, request: dict[str, Any]) -> None:
        op = request.get(WorkerProtocol.OP)
        request_id = request.get(WorkerProtocol.ID)
        match op:
            case WorkerProtocol.PING:
                self._emit(
                    {
                        WorkerProtocol.EVENT: WorkerProtocol.READY,
                        WorkerProtocol.PROTOCOL: WorkerProtocol.VERSION,
                    }
                )
            case WorkerProtocol.PRESETS:
                presets = {preset.value: asdict(preset.settings()) for preset in EnhancePreset}
                self._emit(
                    {WorkerProtocol.EVENT: WorkerProtocol.PRESETS, WorkerProtocol.PRESETS: presets}
                )
            case WorkerProtocol.ANALYZE:
                await self._analyze(request_id, request)
            case WorkerProtocol.ENHANCE:
                await self._enhance(request_id, request)
            case _:
                self._error(request_id, self._UNKNOWN_OP.format(op=op))

    async def _analyze(self, request_id: object, request: dict[str, Any]) -> None:
        input_path = request.get(WorkerProtocol.INPUT)
        if not isinstance(input_path, str):
            self._error(request_id, self._MISSING_FIELD.format(name=WorkerProtocol.INPUT))
            return
        use_case = analyze_recording_use_case()
        match await use_case(input_path=input_path):
            case Success(analysis):
                self._emit(
                    {
                        WorkerProtocol.EVENT: WorkerProtocol.ANALYSIS,
                        WorkerProtocol.ID: request_id,
                        WorkerProtocol.ANALYSIS: EnhancePayloads.analysis(analysis),
                    }
                )
            case Failure(error):
                self._error(request_id, error)

    async def _enhance(self, request_id: object, request: dict[str, Any]) -> None:
        input_path = request.get(WorkerProtocol.INPUT)
        output_path = request.get(WorkerProtocol.OUTPUT)
        if not isinstance(input_path, str):
            self._error(request_id, self._MISSING_FIELD.format(name=WorkerProtocol.INPUT))
            return
        if not isinstance(output_path, str):
            self._error(request_id, self._MISSING_FIELD.format(name=WorkerProtocol.OUTPUT))
            return
        preset = request.get(WorkerProtocol.PRESET, WorkerProtocol.DEFAULT_PRESET)
        values = request.get(WorkerProtocol.SETTINGS) or {}
        if not isinstance(values, dict):
            self._error(request_id, self._NOT_AN_OBJECT.format(name=WorkerProtocol.SETTINGS))
            return
        match SettingsOverrides(preset=str(preset), values=values).to_entity():
            case Success(settings):
                pass
            case Failure(error):
                self._error(request_id, error)
                return

        def on_progress(progress: EnhanceProgress) -> None:
            self._emit(
                {
                    WorkerProtocol.EVENT: WorkerProtocol.PROGRESS,
                    WorkerProtocol.ID: request_id,
                    **EnhancePayloads.progress(progress),
                }
            )

        use_case = enhance_recording_use_case()
        match await use_case(
            input_path=input_path,
            output_path=output_path,
            settings=settings,
            on_progress=on_progress,
        ):
            case Success(report):
                self._emit(
                    {
                        WorkerProtocol.EVENT: WorkerProtocol.DONE,
                        WorkerProtocol.ID: request_id,
                        WorkerProtocol.REPORT: EnhancePayloads.report(report),
                    }
                )
            case Failure(error):
                self._error(request_id, error)

    def _error(self, request_id: object, message: str) -> None:
        self._emit(
            {
                WorkerProtocol.EVENT: WorkerProtocol.ERROR,
                WorkerProtocol.ID: request_id,
                WorkerProtocol.MESSAGE: message,
            }
        )

    def _emit(self, event: dict[str, Any]) -> None:
        self._send(json.dumps(event, ensure_ascii=False).encode(self._ENCODING))
