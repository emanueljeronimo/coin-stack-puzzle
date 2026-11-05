#!/usr/bin/env python3
"""Generate short Spider-solitaire-style WAV SFX (card, clin, cha-chan)."""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

import numpy as np

SR = 44100
OUT_DIR = Path(__file__).resolve().parents[1] / "musica"


def _write_wav(path: Path, samples: np.ndarray) -> None:
    peak = float(np.max(np.abs(samples))) if samples.size else 1.0
    if peak < 1e-9:
        peak = 1.0
    norm = np.clip(samples / peak * 0.86, -1.0, 1.0)
    pcm = (norm * 32767.0).astype(np.int16)
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        wav.writeframes(pcm.tobytes())


def _env(t: np.ndarray, attack: float, decay: float) -> np.ndarray:
    att = np.clip(t / max(attack, 1e-4), 0.0, 1.0)
    dec = np.exp(-t / max(decay, 1e-4))
    return att * dec


def _tone(t: np.ndarray, hz: float, amp: float, decay: float, attack: float = 0.008) -> np.ndarray:
    return np.sin(2.0 * math.pi * hz * t) * amp * _env(t, attack, decay)


def _lowpass(samples: np.ndarray, cutoff_hz: float) -> np.ndarray:
    rc = 1.0 / (2.0 * math.pi * cutoff_hz)
    a = (1.0 / SR) / (rc + 1.0 / SR)
    out = np.empty_like(samples)
    acc = 0.0
    for i, s in enumerate(samples):
        acc += a * (float(s) - acc)
        out[i] = acc
    return out


def _highpass(samples: np.ndarray, cutoff_hz: float) -> np.ndarray:
    rc = 1.0 / (2.0 * math.pi * cutoff_hz)
    a = rc / (rc + 1.0 / SR)
    out = np.empty_like(samples)
    prev_x = 0.0
    prev_y = 0.0
    for i, s in enumerate(samples):
        y = a * (prev_y + float(s) - prev_x)
        out[i] = y
        prev_x = float(s)
        prev_y = y
    return out


def make_card() -> np.ndarray:
    dur = 0.16
    t = np.linspace(0.0, dur, int(SR * dur), False)
    rng = np.random.default_rng(11)
    noise = rng.normal(0.0, 1.0, t.size)
    brown = np.cumsum(noise)
    brown /= max(float(np.max(np.abs(brown))), 1e-6)
    kernel = np.ones(21) / 21.0
    soft = np.convolve(brown, kernel, mode="same")
    rustle = soft * np.exp(-t * 28.0)
    body = _tone(t, 190.0, 0.22, 0.07, 0.004) + _tone(t, 320.0, 0.12, 0.05, 0.005)
    out = rustle * 0.85 + body
    out *= _env(t, 0.004, 0.055)
    return _lowpass(out, 2400.0)


def make_flip() -> np.ndarray:
    """Ffshpt: dry laminated-card scrape, fast, mid-low."""
    dur = 0.10
    n = int(SR * dur)
    t = np.linspace(0.0, dur, n, False)
    rng = np.random.default_rng(21)
    noise = rng.normal(0.0, 1.0, n)
    scrape = np.zeros(n)
    acc = 0.0
    prev = 0.0
    for i in range(n):
        cut = 1900.0 - 1300.0 * (float(i) / float(max(n - 1, 1)))
        rc = 1.0 / (2.0 * math.pi * max(cut, 200.0))
        a = (1.0 / SR) / (rc + 1.0 / SR)
        acc += a * (float(noise[i]) - acc)
        hp = acc - prev
        prev = acc
        scrape[i] = hp
    scrape *= np.exp(-t * 48.0)
    ff = _highpass(noise, 700.0) * np.exp(-t * 78.0) * 0.42
    cardboard = _tone(t, 220.0, 0.12, 0.028, 0.002)
    pt = np.zeros(n)
    i0 = int(0.040 * SR)
    pt_t = np.linspace(0.0, (n - i0) / float(SR), n - i0, False)
    pt_noise = rng.normal(0.0, 1.0, n - i0) * np.exp(-pt_t * 95.0)
    pt[i0:] = _lowpass(pt_noise, 650.0) * 0.55
    pt[i0:] += _tone(pt_t, 175.0, 0.16, 0.016, 0.001)
    out = scrape * 1.15 + ff + cardboard + pt * 0.9
    out *= _env(t, 0.0018, 0.032)
    return _lowpass(out, 2200.0)


def make_place() -> np.ndarray:
    """Tup/Tack: muted card tap on felt."""
    dur = 0.075
    n = int(SR * dur)
    t = np.linspace(0.0, dur, n, False)
    rng = np.random.default_rng(13)
    thud = _tone(t, 118.0, 0.52, 0.020, 0.0012)
    tap = _tone(t, 310.0, 0.14, 0.009, 0.0008)
    felt = rng.normal(0.0, 1.0, n) * np.exp(-t * 100.0) * 0.20
    felt = _lowpass(felt, 850.0)
    out = thud + tap + felt
    out *= _env(t, 0.0012, 0.022)
    return _lowpass(out, 980.0)


def make_clin() -> np.ndarray:
    dur = 0.70
    n = int(SR * dur)
    t = np.linspace(0.0, dur, n, False)
    # Soft round bells, no high harmonics.
    out = (
        _tone(t, 659.26, 0.42, 0.28, 0.012)
        + _tone(t, 830.61, 0.28, 0.32, 0.014)
        + _tone(t, 987.77, 0.16, 0.24, 0.018)
    )
    return _lowpass(out, 1800.0)


def make_cha_chan() -> np.ndarray:
    dur = 1.45
    n = int(SR * dur)
    out = np.zeros(n)

    def chord(start: float, freqs: list[float], amps: list[float], attack: float, decay: float) -> None:
        i0 = int(start * SR)
        sl = np.linspace(0.0, (n - i0) / float(SR), n - i0, False)
        for hz, amp in zip(freqs, amps):
            out[i0:] += _tone(sl, hz, amp, decay, attack)

    # "cha" — warm low triad
    chord(0.00, [196.00, 246.94, 293.66], [0.34, 0.30, 0.24], 0.018, 0.14)
    # "chaan" — smoother resolving chord, kept in mid range
    chord(0.24, [261.63, 329.63, 392.00, 523.25], [0.32, 0.28, 0.24, 0.16], 0.05, 0.55)
    return _lowpass(out, 1600.0)


def main() -> None:
    _write_wav(OUT_DIR / "sonido-giro.wav", make_flip())
    _write_wav(OUT_DIR / "sonido-colocar.wav", make_place())
    print("wrote", OUT_DIR / "sonido-giro.wav")
    print("wrote", OUT_DIR / "sonido-colocar.wav")


if __name__ == "__main__":
    main()
