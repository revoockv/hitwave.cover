"""Reads and writes PCM WAV files."""

import os
import tempfile
import wave
from abc import ABC, abstractmethod
from dataclasses import dataclass

import numpy as np
import numpy.typing as npt
from scipy.io import wavfile

type Samples = npt.NDArray[np.float64]
"""Audio as floats in -1.0..1.0, shaped ``(channels, frames)``."""


@dataclass(frozen=True, slots=True)
class PcmAudio:
    """Decoded audio: float samples shaped ``(channels, frames)`` and their sample rate."""

    samples: Samples
    sample_rate: int

    @property
    def channels(self) -> int:
        """Number of channels."""
        return int(self.samples.shape[0])

    @property
    def frames(self) -> int:
        """Number of samples per channel."""
        return int(self.samples.shape[1])


class WavFileDataSourceError(Exception):
    """Raised when a WAV file cannot be read or written."""


class WavFileDataSource(ABC):
    """Loads and saves audio. May raise ``WavFileDataSourceError`` or ``OSError``."""

    @abstractmethod
    def read(self, path: str) -> PcmAudio:
        """Decode the WAV file at ``path``."""

    @abstractmethod
    def write(self, path: str, audio: PcmAudio) -> None:
        """Encode ``audio`` as a 24-bit PCM WAV file at ``path`` (replaced atomically)."""


class LocalWavFileDataSource(WavFileDataSource):
    """WAV files on the local disk: 8/16/24/32-bit PCM and 32/64-bit float in, 24-bit PCM out."""

    _INT24_SCALE = float(1 << 23)
    _BYTES_PER_SAMPLE = 3
    _INT32_BYTES = 4
    _UINT8_OFFSET = 128.0

    def read(self, path: str) -> PcmAudio:
        """Decode the WAV file at ``path`` into floats."""
        if not os.path.isfile(path):
            raise WavFileDataSourceError(f"no such file: {path}")
        try:
            sample_rate, data = wavfile.read(path)
        except ValueError as e:
            raise WavFileDataSourceError(f"not a PCM WAV file: {path} ({e})") from e
        samples = self._to_float(np.asarray(data))
        samples = samples[np.newaxis, :] if samples.ndim == 1 else samples.T
        if samples.shape[1] == 0:
            raise WavFileDataSourceError(f"the file has no audio: {path}")
        return PcmAudio(samples=np.ascontiguousarray(samples), sample_rate=int(sample_rate))

    def write(self, path: str, audio: PcmAudio) -> None:
        """Encode ``audio`` as 24-bit PCM, writing a temporary file first and then renaming it."""
        folder = os.path.dirname(os.path.abspath(path))
        os.makedirs(folder, exist_ok=True)
        top = (self._INT24_SCALE - 1) / self._INT24_SCALE
        clipped = np.clip(audio.samples, -1.0, top)
        ints = np.round(clipped * self._INT24_SCALE).astype("<i4")
        interleaved = np.ascontiguousarray(ints.T).reshape(-1)
        raw = interleaved.view(np.uint8).reshape(-1, self._INT32_BYTES)[:, : self._BYTES_PER_SAMPLE]
        handle, temporary = tempfile.mkstemp(suffix=".wav", dir=folder)
        os.close(handle)
        try:
            with wave.open(temporary, "wb") as out:
                out.setnchannels(audio.channels)
                out.setsampwidth(self._BYTES_PER_SAMPLE)
                out.setframerate(audio.sample_rate)
                out.writeframes(raw.tobytes())
            os.replace(temporary, path)
        except BaseException:
            if os.path.exists(temporary):
                os.remove(temporary)
            raise

    def _to_float(self, data: npt.NDArray[np.generic]) -> Samples:
        if data.dtype == np.uint8:
            return (data.astype(np.float64) - self._UINT8_OFFSET) / self._UINT8_OFFSET
        if np.issubdtype(data.dtype, np.integer):
            scale = float(np.iinfo(data.dtype.str).max) + 1.0
            return data.astype(np.float64) / scale
        if np.issubdtype(data.dtype, np.floating):
            return data.astype(np.float64)
        raise WavFileDataSourceError(f"unsupported sample type: {data.dtype}")
