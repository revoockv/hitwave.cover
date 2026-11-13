"""Embedded Python entry point (run by serious_python in a background thread).

Connects the vocal_enhance worker to the Dart side through dart_bridge: Dart passes its
native port in HITWAVE_ENHANCE_PORT, sends JSON requests to it and receives JSON events
from it. The engine itself lives in ``vocal_enhance/`` — a copy of the
revoockv-vocal-enhance skill made by its ``scripts/sync_to_app.sh``; do not edit it here.
"""

import json
import os
import threading
import traceback

import dart_bridge

PORT_ENV = "HITWAVE_ENHANCE_PORT"

port = int(os.environ[PORT_ENV])


def send(payload: bytes) -> None:
    dart_bridge.send_bytes(port, payload)


try:
    from vocal_enhance.worker import start_worker

    worker = start_worker(send)
    dart_bridge.set_enqueue_handler_func(port, worker.handle)
except Exception:
    # Without this the app would only see a timeout; the traceback tells what is missing.
    message = {"event": "startup_error", "message": traceback.format_exc()}
    send(json.dumps(message).encode("utf-8"))
    raise

# Keep the interpreter alive; the app drives its lifetime.
threading.Event().wait()
