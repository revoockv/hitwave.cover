"""IIR filters of the chain: high-pass, EQ bands, band-pass and K-weighting."""

import math

import numpy as np
import numpy.typing as npt
from scipy import signal

from vocal_enhance.features.enhance.data.data_sources.wav_file_data_source import Samples

type Sos = npt.NDArray[np.float64]
"""Second-order sections, one ``[b0, b1, b2, a0, a1, a2]`` row each."""


class BiquadFilterService:
    """Builds and applies biquad filters (RBJ cookbook, libebur128 K-weighting)."""

    _MAX_CORNER = 0.45
    """Highest usable corner as a part of the sample rate (keeps clear of Nyquist)."""

    _HIGH_PASS_ORDER = 2
    _BAND_PASS_ORDER = 2
    _EQ_Q = 1.0
    _SHELF_Q = 1 / math.sqrt(2)

    # ITU-R BS.1770 K-weighting as derived in libebur128, valid at any sample rate.
    _K_SHELF_HZ = 1681.974450955533
    _K_SHELF_DB = 3.999843853973347
    _K_SHELF_Q = 0.7071752369554196
    _K_SHELF_VB_EXPONENT = 0.4996667741545416
    _K_HIGH_PASS_HZ = 38.13547087602444
    _K_HIGH_PASS_Q = 0.5003270373238773

    def high_pass(self, samples: Samples, sample_rate: int, *, corner_hz: float) -> Samples:
        """Remove what is below ``corner_hz`` (12 dB per octave)."""
        corner = min(corner_hz, sample_rate * self._MAX_CORNER)
        sos = signal.butter(
            self._HIGH_PASS_ORDER, corner, btype="highpass", fs=sample_rate, output="sos"
        )
        return np.asarray(signal.sosfilt(sos, samples, axis=-1), dtype=np.float64)

    def band(self, samples: Samples, sample_rate: int, *, low_hz: float, high_hz: float) -> Samples:
        """Keep ``low_hz``-``high_hz`` without phase shift (filtered forwards and backwards)."""
        high = min(high_hz, sample_rate * self._MAX_CORNER)
        if low_hz >= high:
            return np.zeros_like(samples)
        sos = signal.butter(
            self._BAND_PASS_ORDER, [low_hz, high], btype="bandpass", fs=sample_rate, output="sos"
        )
        return np.asarray(signal.sosfiltfilt(sos, samples, axis=-1), dtype=np.float64)

    def equalize(
        self,
        samples: Samples,
        sample_rate: int,
        *,
        bells: list[tuple[float, float]],
        high_shelf: tuple[float, float] | None,
    ) -> Samples:
        """Apply peaking bands ``(hz, gain_db)`` and an optional high shelf ``(hz, gain_db)``."""
        rows = [self._peaking(hz, gain, sample_rate) for hz, gain in bells if gain != 0 and hz > 0]
        if high_shelf is not None and high_shelf[1] != 0:
            rows.append(self._high_shelf(high_shelf[0], high_shelf[1], sample_rate))
        if not rows:
            return samples
        return np.asarray(signal.sosfilt(np.array(rows), samples, axis=-1), dtype=np.float64)

    def k_weighting(self, sample_rate: int) -> Sos:
        """Return the two K-weighting stages of ITU-R BS.1770 for ``sample_rate``."""
        k = math.tan(math.pi * self._K_SHELF_HZ / sample_rate)
        vh = 10 ** (self._K_SHELF_DB / 20)
        vb = vh**self._K_SHELF_VB_EXPONENT
        q = self._K_SHELF_Q
        a0 = 1 + k / q + k * k
        shelf = [
            (vh + vb * k / q + k * k) / a0,
            2 * (k * k - vh) / a0,
            (vh - vb * k / q + k * k) / a0,
            1.0,
            2 * (k * k - 1) / a0,
            (1 - k / q + k * k) / a0,
        ]
        k = math.tan(math.pi * self._K_HIGH_PASS_HZ / sample_rate)
        q = self._K_HIGH_PASS_Q
        a0 = 1 + k / q + k * k
        high_pass = [1.0, -2.0, 1.0, 1.0, 2 * (k * k - 1) / a0, (1 - k / q + k * k) / a0]
        return np.array([shelf, high_pass], dtype=np.float64)

    def _peaking(self, hz: float, gain_db: float, sample_rate: int) -> list[float]:
        w0 = 2 * math.pi * min(hz, sample_rate * self._MAX_CORNER) / sample_rate
        a = 10 ** (gain_db / 40)
        alpha = math.sin(w0) / (2 * self._EQ_Q)
        cos = math.cos(w0)
        a0 = 1 + alpha / a
        return [
            (1 + alpha * a) / a0,
            -2 * cos / a0,
            (1 - alpha * a) / a0,
            1.0,
            -2 * cos / a0,
            (1 - alpha / a) / a0,
        ]

    def _high_shelf(self, hz: float, gain_db: float, sample_rate: int) -> list[float]:
        w0 = 2 * math.pi * min(hz, sample_rate * self._MAX_CORNER) / sample_rate
        a = 10 ** (gain_db / 40)
        alpha = math.sin(w0) / (2 * self._SHELF_Q)
        cos = math.cos(w0)
        root = 2 * math.sqrt(a) * alpha
        a0 = (a + 1) - (a - 1) * cos + root
        return [
            a * ((a + 1) + (a - 1) * cos + root) / a0,
            -2 * a * ((a - 1) + (a + 1) * cos) / a0,
            a * ((a + 1) + (a - 1) * cos - root) / a0,
            1.0,
            2 * ((a - 1) - (a + 1) * cos) / a0,
            ((a + 1) - (a - 1) * cos - root) / a0,
        ]
