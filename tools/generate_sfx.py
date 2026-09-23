"""Genera los efectos de sonido placeholder del juego (audio/sfx/*.wav).

Son sonidos sintetizados simples, pensados para ser reemplazados por los
definitivos: basta con dejar un archivo con el mismo nombre en audio/sfx/
(o cambiar su ruta en scripts/sfx.gd).

Uso (desde la raíz del proyecto):  python tools/generate_sfx.py
Requiere numpy.
"""

import os
import wave

import numpy as np

SR = 22050  # Hz, mono 16-bit: liviano para web
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "audio", "sfx")
rng = np.random.default_rng(7)  # semilla fija: mismo resultado cada vez


def time(seconds):
    return np.arange(int(SR * seconds)) / SR


def lowpass(x, cutoff):
    """Filtro pasa-bajos de un polo (cutoff puede ser escalar o array)."""
    cutoff = np.broadcast_to(cutoff, x.shape)
    a = 1.0 - np.exp(-2.0 * np.pi * cutoff / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += a[i] * (x[i] - acc)
        y[i] = acc
    return y


def bandpass(x, center, q=2.0):
    """Filtro pasa-banda de variable de estado (center puede variar en el tiempo)."""
    center = np.broadcast_to(center, x.shape)
    y = np.zeros_like(x)
    low = band = 0.0
    damp = 1.0 / q
    for i in range(len(x)):
        f = 2.0 * np.sin(np.pi * min(center[i], SR / 6) / SR)
        low += f * band
        high = x[i] - low - damp * band
        band += f * high
        y[i] = band
    return y


def triangle(phase):
    return 2.0 / np.pi * np.arcsin(np.sin(phase))


def square(phase, duty=0.5):
    return np.where((phase / (2 * np.pi)) % 1.0 < duty, 1.0, -1.0)


def sweep_phase(f):
    return 2.0 * np.pi * np.cumsum(f) / SR


def attack(n, seconds):
    env = np.ones(n)
    k = min(n, int(SR * seconds))
    env[:k] = np.linspace(0.0, 1.0, k)
    return env


def normalize(x, peak_db=-3.0):
    peak = np.max(np.abs(x))
    return x if peak == 0 else x / peak * 10 ** (peak_db / 20)


def write(name, x):
    os.makedirs(OUT_DIR, exist_ok=True)
    data = (np.clip(normalize(x), -1, 1) * 32767).astype("<i2")
    path = os.path.join(OUT_DIR, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print("  %s.wav  %.0f ms" % (name, 1000 * len(x) / SR))


def step():
    # Golpe suave (seno grave que cae) + un roce corto de ruido.
    t = time(0.07)
    thump = np.sin(sweep_phase(np.linspace(140, 80, len(t)))) * np.exp(-t / 0.025)
    scuff = lowpass(rng.uniform(-1, 1, len(t)), 1500) * np.exp(-t / 0.012) * 0.8
    return (thump + scuff) * attack(len(t), 0.002)


def jump():
    # "Boing" ascendente: triángulo + un poco de cuadrada para el color.
    t = time(0.16)
    f = 300 * (750 / 300) ** (t / t[-1])
    ph = sweep_phase(f)
    tone = triangle(ph) + 0.25 * square(ph, 0.25)
    return tone * attack(len(t), 0.005) * (1 - t / t[-1]) ** 1.5


def die():
    # Tres notas que bajan (Re, Si, Sol) y un glissando final hacia el grave.
    parts = []
    for freq in (587.3, 493.9, 392.0):
        t = time(0.1)
        ph = 2 * np.pi * freq * t
        note = (triangle(ph) + 0.3 * square(ph)) * attack(len(t), 0.004) * np.exp(-t / 0.08)
        parts += [note, np.zeros(int(SR * 0.02))]
    t = time(0.25)
    ph = sweep_phase(np.linspace(392, 140, len(t)))
    parts.append((triangle(ph) + 0.3 * square(ph)) * attack(len(t), 0.004) * (1 - t / t[-1]) ** 2)
    return np.concatenate(parts)


def hook():
    # "Clink" metálico: senos inarmónicos con caída rápida + un click de ataque.
    t = time(0.25)
    ring = (
        np.sin(2 * np.pi * 1230 * t) * np.exp(-t / 0.12)
        + 0.6 * np.sin(2 * np.pi * 1890 * t) * np.exp(-t / 0.08)
        + 0.4 * np.sin(2 * np.pi * 2710 * t) * np.exp(-t / 0.05)
        + 0.5 * np.sin(2 * np.pi * 310 * t) * np.exp(-t / 0.03)
    )
    click = rng.uniform(-1, 1, len(t)) * np.exp(-t / 0.002)
    return ring + click


def swing():
    # "Whoosh": ruido por un pasa-banda que sube y baja, con envolvente de campana.
    t = time(0.3)
    bell = np.sin(np.pi * t / t[-1])
    center = 400 + 1400 * bell
    return bandpass(rng.uniform(-1, 1, len(t)), center, q=1.5) * bell ** 2


def grab():
    # "Tomar": golpecito de madera en la mano (seno medio que cae rápido) + un click.
    t = time(0.09)
    knock = np.sin(sweep_phase(np.linspace(520, 330, len(t)))) * np.exp(-t / 0.02)
    body = 0.5 * np.sin(2 * np.pi * 180 * t) * np.exp(-t / 0.03)
    click = lowpass(rng.uniform(-1, 1, len(t)), 3000) * np.exp(-t / 0.003) * 0.7
    return (knock + body + click) * attack(len(t), 0.001)


def throw():
    # "Lanzar": whoosh corto y ascendente (más agudo y rápido que el del balanceo).
    t = time(0.2)
    rise = (t / t[-1]) ** 0.7
    center = 700 + 2600 * rise
    env = np.sin(np.pi * np.minimum(t / (t[-1] * 0.6), 1.0) / 2) * (1 - t / t[-1]) ** 1.2
    return bandpass(rng.uniform(-1, 1, len(t)), center, q=2.0) * env


def box_push():
    # Arrastre en loop: ruido grave con "granos" a 14 Hz. Dura 0.5 s (7 ciclos
    # exactos de la modulación) y los extremos se funden para que el loop no se note.
    loop = int(SR * 0.5)
    fade = int(SR * 0.05)
    t = np.arange(loop + fade) / SR
    noise = np.cumsum(rng.uniform(-1, 1, len(t)))
    noise -= lowpass(noise, 20)  # quita la deriva del ruido marrón
    body = lowpass(noise, 700)
    grains = 0.55 + 0.45 * np.abs(np.sin(2 * np.pi * 7 * t))
    x = body * grains
    ramp = np.linspace(0, 1, fade)
    x[:fade] = x[:fade] * ramp + x[loop:loop + fade] * (1 - ramp)
    return x[:loop]


if __name__ == "__main__":
    print("Generando efectos en", os.path.normpath(OUT_DIR))
    for fn in (step, jump, die, hook, swing, box_push, grab, throw):
        write(fn.__name__, fn())
