"""Settings chosen by a preset name plus individual overrides."""

from dataclasses import dataclass, fields, replace
from typing import Self

from vocal_enhance.core.domain.entities.result import Failure, Result, Success
from vocal_enhance.features.enhance.domain.entities.enhance_preset import EnhancePreset
from vocal_enhance.features.enhance.domain.entities.enhance_settings import EnhanceSettings


@dataclass(frozen=True, slots=True)
class SettingsOverrides:
    """A preset and the settings changed on top of it, as received from a CLI or JSON."""

    _ASSIGNMENT = "="
    _UNKNOWN_PRESET = "Unknown preset {name!r}; choose one of: {choices}"
    _UNKNOWN_SETTING = "Unknown setting {name!r}; known settings: {choices}"
    _NOT_A_NUMBER = "Setting {name!r} must be a number, got {value!r}"
    _NOT_AN_ASSIGNMENT = "Expected name=value, got {text!r}"
    _CHOICE_SEPARATOR = ", "

    preset: str
    values: dict[str, object]

    @classmethod
    def from_assignments(cls, preset: str, assignments: list[str]) -> Result[Self]:
        """Parse ``["noise_reduction_db=18", …]`` from the command line."""
        values: dict[str, object] = {}
        for text in assignments:
            name, separator, value = text.partition(cls._ASSIGNMENT)
            if not separator:
                return Failure(cls._NOT_AN_ASSIGNMENT.format(text=text))
            values[name.strip()] = value.strip()
        return Success(cls(preset=preset, values=values))

    def to_entity(self) -> Result[EnhanceSettings]:
        """Return the preset's settings with every override applied."""
        try:
            preset = EnhancePreset(self.preset)
        except ValueError:
            choices = self._CHOICE_SEPARATOR.join(item.value for item in EnhancePreset)
            return Failure(self._UNKNOWN_PRESET.format(name=self.preset, choices=choices))
        names = {field.name for field in fields(EnhanceSettings)}
        changes: dict[str, float] = {}
        for name, value in self.values.items():
            if name not in names:
                choices = self._CHOICE_SEPARATOR.join(sorted(names))
                return Failure(self._UNKNOWN_SETTING.format(name=name, choices=choices))
            number = self._number(value)
            if number is None:
                return Failure(self._NOT_A_NUMBER.format(name=name, value=value))
            changes[name] = number
        return Success(replace(preset.settings(), **changes))

    @staticmethod
    def _number(value: object) -> float | None:
        if isinstance(value, bool):
            return None
        if isinstance(value, int | float):
            return float(value)
        if isinstance(value, str):
            try:
                return float(value)
            except ValueError:
                return None
        return None
