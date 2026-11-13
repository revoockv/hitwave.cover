"""Main DI: registers core and every feature, then runs one-time initiations."""

from vocal_enhance.core.presentation.di.container import container
from vocal_enhance.core.presentation.di.core_di import register_core
from vocal_enhance.features.enhance.presentation.di.enhance_di import register_enhance


async def register_and_init() -> None:
    """Reset the container, register all dependencies and run feature initiations.

    The single DI entry point; ``main.py`` calls nothing else.
    """
    container.reset()
    register_core(container)
    # <features>
    register_enhance(container)
    # </features>
