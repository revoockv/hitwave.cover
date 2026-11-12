"""Second entry point: the message worker embedded in the hitwave.cover app.

The app's ``main.py`` (run by serious_python) connects it to the Dart bridge::

    import os, threading
    import dart_bridge
    from vocal_enhance.worker import start_worker

    port = int(os.environ["HITWAVE_ENHANCE_PORT"])
    worker = start_worker(lambda payload: dart_bridge.send_bytes(port, payload))
    dart_bridge.set_enqueue_handler_func(port, worker.handle)
    threading.Event().wait()

Nothing here imports typer, so the CLI does not need to ship with the app.
"""

import asyncio

from vocal_enhance.di import register_and_init
from vocal_enhance.features.enhance.presentation.worker.enhance_worker import (
    EnhanceWorker,
    Send,
)


def start_worker(send: Send) -> EnhanceWorker:
    """Register the dependencies, start a worker that answers through ``send`` and return it."""
    asyncio.run(register_and_init())
    worker = EnhanceWorker(send)
    worker.start()
    return worker
