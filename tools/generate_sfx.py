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


def plate():
    # Placa de presión: "clac" de madera grave (sube un poco el tono) + click seco.
    t = time(0.12)
    knock = np.sin(sweep_phase(np.linspace(240, 300, len(t)))) * np.exp(-t / 0.025)
    click = lowpass(rng.uniform(-1, 1, len(t)), 2500) * np.exp(-t / 0.004) * 0.8
    return (knock + click) * attack(len(t), 0.001)


def gate():
    # Compuerta: madera que se desliza (ruido grave con granos) y un golpe al final.
    t = time(0.55)
    noise = np.cumsum(rng.uniform(-1, 1, len(t)))
    noise -= lowpass(noise, 20)
    slide = lowpass(noise, 500) * (0.6 + 0.4 * np.abs(np.sin(2 * np.pi * 11 * t)))
    slide *= np.minimum(t / 0.05, 1.0) * np.clip((0.45 - t) / 0.1, 0.0, 1.0)
    thud_t = np.clip(t - 0.42, 0.0, None)
    thud = np.where(t > 0.42, np.sin(2 * np.pi * 90 * thud_t) * np.exp(-thud_t / 0.05), 0.0)
    return slide * 0.8 + thud


def wind():
    # Corriente de aire en loop: ruido filtrado que "respira" lento. 2 s exactos
    # con los extremos fundidos para que el loop no se note.
    loop = int(SR * 2.0)
    fade = int(SR * 0.2)
    t = np.arange(loop + fade) / SR
    center = 500 + 300 * np.sin(2 * np.pi * 0.5 * t)
    x = bandpass(rng.uniform(-1, 1, len(t)), center, q=0.8)
    x *= 0.75 + 0.25 * np.sin(2 * np.pi * 1.0 * t + 1.0)
    ramp = np.linspace(0, 1, fade)
    x[:fade] = x[:fade] * ramp + x[loop:loop + fade] * (1 - ramp)
    return x[:loop]


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def emboque_click():
    # El palito entra en la campana: "cli-click" de juguete de madera. Un ataque
    # seco + resonancias de madera hueca, y un segundo click más chico 22 ms
    # después (el palito que se asienta al fondo).
    def clack(t, gain):
        hit = highpass(rng.uniform(-1, 1, len(t)), 2500) * np.exp(-t / 0.0015)
        wood = (
            np.sin(2 * np.pi * 1050 * t) * np.exp(-t / 0.035)
            + 0.7 * np.sin(2 * np.pi * 2350 * t) * np.exp(-t / 0.02)
            + 0.35 * np.sin(2 * np.pi * 3900 * t) * np.exp(-t / 0.01)
            + 0.6 * np.sin(2 * np.pi * 420 * t) * np.exp(-t / 0.05)
        )
        return (hit * 0.9 + wood) * gain

    t = time(0.3)
    x = clack(t, 1.0)
    d = int(SR * 0.022)
    x[d:] += clack(t[: len(t) - d], 0.55)
    # Un brillo muy corto encima: que se sienta como un "logro".
    x += 0.18 * np.sin(2 * np.pi * 1760 * t) * np.exp(-t / 0.12) * attack(len(t), 0.003)
    # Saturación suave: más cuerpo y volumen percibido con el mismo pico (que no
    # sature la mezcla al sonar sobre los tambores).
    x = np.tanh(x / np.max(np.abs(x)) * 3.0)
    return x * attack(len(t), 0.0005)


def sparkle():
    # Brillo sutil de las partículas doradas: campanitas agudas (pentatónica alta)
    # que aparecen al azar, más seguidas al principio, y un soplo de aire agudo.
    t = time(1.3)
    x = np.zeros(len(t))
    notes = (2093.0, 2349.3, 2637.0, 3136.0, 3520.0, 4186.0)
    starts = np.sort(rng.uniform(0, 1, 11) ** 1.8 * 0.85)
    for k, s in enumerate(starts):
        i = int(s * SR)
        tt = t[: len(t) - i]
        f = notes[rng.integers(len(notes))] * rng.uniform(0.995, 1.005)
        decay = rng.uniform(0.1, 0.22)
        ting = (np.sin(2 * np.pi * f * tt) + 0.25 * np.sin(2 * np.pi * 2 * f * tt)) * np.exp(-tt / decay)
        x[i:] += ting * attack(len(tt), 0.002) * (1.0 - 0.6 * s) * rng.uniform(0.6, 1.0)
    air = bandpass(rng.uniform(-1, 1, len(t)), 6500, q=1.2) * np.exp(-t / 0.35) * 0.25
    return (x + air) * np.clip((t[-1] - t) / 0.1, 0, 1)


def confetti_pop():
    # Lanzador de confetti: "pop" seco (ruido + golpe grave) desde cada esquina
    # (dos pops casi juntos) y el papel que cruje mientras vuela.
    def pop(t):
        burst = bandpass(rng.uniform(-1, 1, len(t)), 1300, q=0.9) * np.exp(-t / 0.012)
        thump = np.sin(sweep_phase(np.linspace(140, 60, len(t)))) * np.exp(-t / 0.035) * 0.8
        return burst * 1.6 + thump

    t = time(0.75)
    x = pop(t)
    d = int(SR * 0.035)
    x[d:] += 0.8 * pop(t[: len(t) - d])
    # Crujido de papel: ruido agudo en granos al azar, que se apaga.
    grains = (rng.uniform(0, 1, len(t)) < 0.004).astype(float)
    grains = lowpass(grains, 300) * 40
    rustle = bandpass(rng.uniform(-1, 1, len(t)), 4200, q=1.0) * np.clip(grains, 0, 1)
    rustle *= np.clip((t - 0.02) / 0.05, 0, 1) * np.exp(-t / 0.3) * 0.5
    return (x + rustle) * attack(len(t), 0.0005)


# --- Interfaz (menús, mapa, pausa; los reproduce el autoload UiFx) -------------
# Familia de sonidos de madera + cuerda pulsada (como un charango), para que la
# interfaz suene al mismo mundo que el emboque.


def pluck(freq, seconds, damping=0.996, brightness=0.6):
    """Cuerda pulsada (Karplus-Strong): ruido en una línea de retardo que se
    promedia a sí mismo. brightness < 1 suaviza el ataque (cuerda más opaca)."""
    n = int(SR * seconds)
    period = max(2, int(round(SR / freq)))
    buf = rng.uniform(-1, 1, period)
    buf = lowpass(buf, 2000 + 8000 * brightness)
    out = np.zeros(n)
    for i in range(n):
        k = i % period
        out[i] = buf[k]
        buf[k] = damping * 0.5 * (buf[k] + buf[(k + 1) % period])
    return out


def wood_knock(t, pitch=1.0):
    """Golpe de madera hueca (wood block): ataque de ruido + 3 resonancias."""
    hit = highpass(rng.uniform(-1, 1, len(t)), 2000) * np.exp(-t / 0.0012)
    body = (
        np.sin(2 * np.pi * 820 * pitch * t) * np.exp(-t / 0.028)
        + 0.55 * np.sin(2 * np.pi * 1960 * pitch * t) * np.exp(-t / 0.015)
        + 0.5 * np.sin(2 * np.pi * 360 * pitch * t) * np.exp(-t / 0.03)
    )
    return hit * 0.7 + body


def fade_tail(x, seconds=0.012):
    """Fundido final corto (que el sonido no termine con un click)."""
    k = min(len(x), int(SR * seconds))
    x = x.copy()
    x[-k:] *= np.linspace(1.0, 0.0, k)
    return x


def place(total, parts):
    """Mezcla [(inicio_s, señal), ...] en un buffer de total segundos."""
    x = np.zeros(int(SR * total))
    for start, sig in parts:
        i = int(SR * start)
        m = min(len(sig), len(x) - i)
        x[i:i + m] += sig[:m]
    return x


def ui_hover():
    # Mouse encima / foco: "tic" de madera muy corto y suave, agudo.
    t = time(0.045)
    tick = bandpass(rng.uniform(-1, 1, len(t)), 3200, q=4.0) * np.exp(-t / 0.004)
    tone = np.sin(2 * np.pi * 2350 * t) * np.exp(-t / 0.012) * 0.6
    return fade_tail((tick + tone) * attack(len(t), 0.0008))


def ui_tick():
    # Slider / conteo de puntos: un "tic" aún más corto (se le cambia el tono).
    t = time(0.03)
    return fade_tail(np.sin(2 * np.pi * 1700 * t) * np.exp(-t / 0.006) * attack(len(t), 0.0005))


def ui_click():
    # Botón apretado: golpe de madera seco con cuerpo.
    t = time(0.12)
    x = wood_knock(t)
    return fade_tail(np.tanh(x / np.max(np.abs(x)) * 2.0) * attack(len(t), 0.0005), 0.03)


def ui_confirm():
    # Jugar / entrar a un nivel / continuar: golpe de madera + dos notas de cuerda
    # que suben una quinta (Sol → Re), brillantes.
    t = time(0.12)
    knock = wood_knock(t, 1.1) * 0.6
    x = place(0.55, [
        (0.0, knock),
        (0.0, pluck(784.0, 0.5, 0.995, 0.8) * 0.9),
        (0.075, pluck(1174.7, 0.47, 0.995, 0.8)),
    ])
    return x * np.clip((0.55 - time(0.55)) / 0.08, 0, 1)


def ui_back():
    # Volver / cancelar: golpe más grave y dos notas que bajan (Re → Sol), suaves.
    t = time(0.1)
    knock = wood_knock(t, 0.8) * 0.6
    x = place(0.4, [
        (0.0, knock),
        (0.0, pluck(1174.7 / 2, 0.38, 0.993, 0.45) * 0.9),
        (0.06, pluck(784.0 / 2, 0.34, 0.993, 0.45)),
    ])
    return x * np.clip((0.4 - time(0.4)) / 0.06, 0, 1)


def ui_locked():
    # Nivel bloqueado / no se puede: "tuc-tuc" de madera apagado, grave.
    t = time(0.09)
    thud = (np.sin(sweep_phase(np.linspace(260, 170, len(t)))) * np.exp(-t / 0.03)
            + 0.4 * lowpass(rng.uniform(-1, 1, len(t)), 900) * np.exp(-t / 0.008))
    return place(0.2, [(0.0, thud), (0.095, thud * 0.75)])


def ui_open():
    # Abrir la pausa: soplo de aire que sube + una nota de cuerda.
    t = time(0.3)
    air = bandpass(rng.uniform(-1, 1, len(t)), np.linspace(700, 2800, len(t)), q=1.5)
    air *= np.sin(np.pi * t / t[-1]) ** 2 * 0.8
    note = place(0.3, [(0.12, pluck(987.8, 0.18, 0.993, 0.5) * 0.5)])
    return fade_tail((air + note) * attack(len(t), 0.002), 0.03)


def ui_unlock():
    # Nivel nuevo en el mapa: arpegio de cuerda que sube (Sol Si Re Sol) + brillo.
    notes = (784.0, 987.8, 1174.7, 1568.0)
    parts = [(0.07 * k, pluck(f, 0.6 - 0.05 * k, 0.996, 0.85) * (0.8 + 0.07 * k))
             for k, f in enumerate(notes)]
    t = time(0.8)
    shimmer = np.sin(2 * np.pi * 3136.0 * t) * np.exp(-t / 0.25) * 0.15
    x = place(0.8, parts) + place(0.8, [(0.21, shimmer)])
    return x * np.clip((0.8 - time(0.8)) / 0.1, 0, 1)


ALL = (step, jump, die, hook, swing, box_push, grab, throw, plate, gate, wind,
       emboque_click, sparkle, confetti_pop,
       ui_hover, ui_tick, ui_click, ui_confirm, ui_back, ui_locked, ui_open, ui_unlock)

if __name__ == "__main__":
    import sys
    # Sin argumentos genera todos; con nombres, solo esos (p. ej. "plate gate").
    wanted = set(sys.argv[1:])
    print("Generando efectos en", os.path.normpath(OUT_DIR))
    for fn in ALL:
        if not wanted or fn.__name__ in wanted:
            write(fn.__name__, fn())
