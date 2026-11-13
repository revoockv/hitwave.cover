"""Progress of the enhancement chain."""

from collections.abc import Callable
from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class EnhanceProgress:
    """The step that has just started."""

    step: int
    """1-based number of the step."""
    steps: int
    label: str

    @property
    def fraction(self) -> float:
        """Part of the work done before this step, 0.0-1.0."""
        return (self.step - 1) / self.steps


type EnhanceProgressListener = Callable[[EnhanceProgress], None]
"""Called on the processing thread when a step starts."""
