"""Compone y graba las cuecas instrumentales del juego (audio/musica/*.mp3).

Son composiciones ORIGINALES (melodías escritas a mano en este archivo, sin
derechos de terceros) con la forma de la cueca tradicional chilena, cada una en
un estilo distinto de la tradición:

    cueca_del_emboque               campesina: arpa, guitarra, pandero, tamboreo en el arpa
    cueca_brava_del_puerto          chilenera / porteña: piano, acordeón, pandero, tormento
    cueca_nortina_de_la_sopaipilla  nortina: banda de bronces (trompetas, trombones, tuba,
                                    bombo, caja y platillos), como en La Tirana
    cueca_chilota_de_los_dos        chilota: acordeón, violín, guitarra y bombo

Los instrumentos son muestras reales del SoundFont GeneralUser GS (S. Christian
Collins; licencia: uso libre para crear música, también comercial). Se descarga
solo a tools/.cache/ la primera vez (o se indica otro con la variable MUSIC_SF2).

Forma de cada cueca (se tocan dos "pies", como en la cueca bailada; en el
segundo cambia el instrumento de la melodía):
    entrada      2 compases (solo ritmo)
    introducción 8 compases
    cuarteta     8 + 8 (la primera queda en la dominante, la segunda cierra)
    seguidilla   8 + 8 (sube al IV pasando por el I7)
    remate       4
La melodía va en 6/8 y el acompañamiento alterna 6/8 y 3/4 de un compás al otro
(sesquiáltera), con la segunda voz en terceras (el "dúo" de la cueca cantada).

Uso (desde la raíz del proyecto):
    python tools/generate_music.py                     # todas
    python tools/generate_music.py cueca_del_emboque   # solo esa
Requiere numpy, tinysoundfont (pip install --no-deps tinysoundfont) y ffmpeg con
libmp3lame en el PATH.
"""

import os
import re
import subprocess
import sys
import tempfile
import urllib.request
import wave

import numpy as np
import tinysoundfont

SR = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(HERE, "..", "audio", "musica")
SF2_URL = "https://github.com/mrbumpy409/GeneralUser-GS/raw/main/GeneralUser-GS.sf2"
SF2_PATH = os.environ.get("MUSIC_SF2", os.path.join(HERE, ".cache", "GeneralUser-GS.sf2"))

MAJOR = (0, 2, 4, 5, 7, 9, 11)
# Acordes: semitonos desde la tónica, la fundamental primero.
CHORDS = {
    "I": (0, 4, 7),
    "I7": (0, 4, 7, 10),
    "IV": (5, 9, 0),
    "V": (7, 11, 2),
    "V7": (7, 11, 2, 5),
}
BAR = 6  # corcheas por compás

# Instrumentos: (banco, preset GM, octava respecto de la melodía escrita).
INSTRUMENTS = {
    "arpa": (0, 46, 0),
    "acordeon": (0, 21, 0),
    "piano": (0, 0, 0),
    "guitarra": (0, 24, 0),
    "violin": (0, 40, 0),
    "trompeta": (0, 56, 0),
    "trombon": (0, 57, -1),
    "tuba": (0, 58, 0),
}
# Percusión (notas GM del canal de batería).
DRUM = {
    "pandero": 54,      # pandereta: las sonajas
    "parche": 64,       # la mano en el parche del pandero (conga grave)
    "madera": 77,       # tamboreo en la caja del arpa (wood block grave)
    "madera_aguda": 76,  # tormento (wood block agudo)
    "palmas": 39,
    "bombo": 36,
    "caja": 38,
    "platillo": 49,
}

# --- Las cuecas -------------------------------------------------------------------
# Melodías en grados de la escala mayor: 1..7, ' = octava arriba, , = abajo,
# b/# = alteración; ":n" = duración en corcheas (1 si se omite); r = silencio.
# Cada compás suma 6 corcheas. Acordes: uno por compás.

EMBOQUE = {
    "intro": ("I I V V V V I I",
              "5:2 3 5:2 3 | 1':3 5 4 3 | 4:2 2 4:2 2 | 7:2 6 5:2 4 |"
              "2 3 4 5 6 7 | 2':2 1':2 7:2 | 1':2 5 3:2 5 | 1':3 r:3"),
    "cuarteta_a": ("I I V V I I V V",
                   "r 3 3 3:2 4 | 5:2 5 5:2 3 | 4:2 4 4 3 2 | 2:3 r 2 3 |"
                   "5:2 3 1:2 3 | 5:2 6 5 4 3 | 2:2 2 7,:2 2 | 5:3 r:3"),
    "cuarteta_b": ("I I V V V V I I",
                   "r 3 3 3:2 4 | 5:2 5 5:2 3 | 4:2 4 4 3 2 | 2:3 r 2 3 |"
                   "4:2 2 7,:2 2 | 5:2 4 2:3 | 1:2 3 5:2 3 | 1:3 r:3"),
    "seguidilla_a": ("I7 IV IV I V V I I",
                     "r 5 5 b7:2 5 | 6:2 6 6:2 1' | 1':2 6 4:2 6 | 5:2 4 3:2 r |"
                     "2:2 5 7:2 5 | 2':2 1':2 7:2 | 1':2 5 3:2 5 | 1':3 r:3"),
    "seguidilla_b": ("I7 IV IV I V V I I",
                     "1':2 1' b7:2 5 | 6:2 1' 6:2 4 | 4 6 1' 6:3 | 5:2 3 1:2 3 |"
                     "2:2 2 2 3 4 | 5:2 4 2:2 7, | 1:2 3 5:2 3 | 1:4 r:2"),
    "remate": ("V V I I",
               "7,:2 2 5:2 4 | 4:2 2 7,:2 2 | 3:2 5 1':2 5 | 1':3 r:3"),
}

PUERTO = {
    "intro": ("I I V V V V I I",
              "3 4 5 1':2 5 | 3:2 1 3:2 5 | 4 5 6 7:2 6 | 5:2 2 7,:2 2 |"
              "4:2 4 4 5 4 | 2:2 7, 5,:2 7, | 1 2 3 5:2 3 | 1:3 r:3"),
    "cuarteta_a": ("I I V V I I V V",
                   "r 5 5 5 6 5 | 3:2 1 3:2 5 | 4 4 4 2:2 4 | 5:3 r 5 5 |"
                   "1':2 1' 5:2 6 | 5:2 3 1:2 3 | 2 2 2 4:2 2 | 7,:3 r:3"),
    "cuarteta_b": ("I I V V V V I I",
                   "r 5 5 5 6 5 | 3:2 1 3:2 5 | 4 4 4 2:2 4 | 5:3 r 5 5 |"
                   "4:2 4 4 3 2 | 7,:2 2 5:2 4 | 3:2 5 3:2 2 | 1:3 r:3"),
    "seguidilla_a": ("I7 IV IV I V V I I",
                     "1':2 b7 b7:2 1' | 6:3 4:3 | 6 1' 6 4:2 6 | 5:3 3:3 |"
                     "2 2 2 4:2 2 | 5 4 2 7,:2 2 | 1 3 5 1':2 5 | 3:3 r:3"),
    "seguidilla_b": ("I7 IV IV I V V I I",
                     "5 5 5 b7:2 5 | 6:2 6 1':2 6 | 4:2 6 1':2 6 | 5:2 3 1:2 3 |"
                     "4:2 4 4 5 4 | 2:2 7, 5,:2 7, | 1 2 3 5:2 3 | 1:4 r:2"),
    "remate": ("V V I I",
               "7, 2 4 7:2 5 | 4:2 2 7,:2 2 | 1 3 5 1':2 5 | 1':3 r:3"),
}

SOPAIPILLA = {
    "intro": ("I I V V V V I I",
              "1 3 5 1':3 | 1':2 5 3:2 5 | 7, 2 4 5:3 | 5:2 4 2:2 7, |"
              "2:2 2 4:2 4 | 5:2 5 7:2 5 | 1':2 5 3 2 1 | 1:3 r:3"),
    "cuarteta_a": ("I I V V I I V V",
                   "r 3 3 3 2 3 | 5:2 3 1:2 3 | 2:2 2 2 7, 2 | 4:3 r:3 |"
                   "5 5 5 1':2 5 | 3:2 3 5 4 3 | 2:2 4 7,:2 2 | 5,:3 r:3"),
    "cuarteta_b": ("I I V V V V I I",
                   "r 3 3 3 2 3 | 5:2 3 1:2 3 | 2:2 2 2 7, 2 | 4:3 r:3 |"
                   "4:2 4 4 2 7, | 2:2 7, 5,:2 7, | 1 3 5 3:2 2 | 1:3 r:3"),
    "seguidilla_a": ("I7 IV IV I V V I I",
                     "5:2 5 b7:2 5 | 6:2 4 1':2 6 | 6 6 6 4:3 | 3:2 5 1':2 5 |"
                     "4 4 4 2:2 4 | 5:3 2:3 | 3:2 2 1:2 3 | 5:3 r:3"),
    "seguidilla_b": ("I7 IV IV I V V I I",
                     "1':2 1' b7 6 5 | 6:2 1' 6:2 4 | 1':2 6 4:2 6 | 5:2 3 1:2 3 |"
                     "2 2 2 4:2 2 | 7,:2 2 5:2 4 | 3 5 1' 5:2 3 | 1:4 r:2"),
    "remate": ("V V I I",
               "5:2 4 2:2 7, | 2:2 4 5:2 7 | 1':2 5 3:2 5 | 1':3 r:3"),
}

CHILOTA = {
    "intro": ("I I V V V V I I",
              "3:2 4 5:3 | 5:2 4 3:3 | 2:2 3 4:3 | 5:2 4 2:3 |"
              "7,:2 1 2:2 4 | 5:3 4 2 7, | 1:2 2 3:2 5 | 1':3 r:3"),
    "cuarteta_a": ("I I V V I I V V",
                   "r 1 2 3:2 3 | 5:2 3 1:3 | 2:2 2 4:2 2 | 7,:3 r:3 |"
                   "r 3 4 5:2 5 | 1':2 7 6 5 3 | 2:2 4 5:2 4 | 2:3 r:3"),
    "cuarteta_b": ("I I V V V V I I",
                   "r 1 2 3:2 3 | 5:2 3 1:3 | 2:2 2 4:2 2 | 7,:3 r:3 |"
                   "r 5 5 4:2 2 | 7,:2 2 5:3 | 3:2 2 1:2 7, | 1:3 r:3"),
    "seguidilla_a": ("I7 IV IV I V V I I",
                     "5:2 5 b7:3 | 6:2 4 1:3 | 4:2 6 1':3 | 5:2 3 1:3 |"
                     "2:2 4 7,:3 | 2:2 7, 5,:3 | 1:2 3 5:2 3 | 1:3 r:3"),
    "seguidilla_b": ("I7 IV IV I V V I I",
                     "1':2 1' b7:2 5 | 6:3 1':3 | 1':2 6 4:2 6 | 5:3 3:3 |"
                     "4:2 2 7,:2 2 | 5:2 4 2:2 7, | 1:2 2 3:2 5 | 1:4 r:2"),
    "remate": ("V V I I",
               "2:2 4 5:2 4 | 2:2 7, 5,:2 7, | 1:2 3 5:2 3 | 1:3 r:3"),
}

SECTIONS = ["intro", "cuarteta_a", "cuarteta_b", "seguidilla_a", "seguidilla_b", "remate"]

# key = MIDI del grado 1 de la melodía escrita; eighth = segundos por corchea.
# pies = (melodía, segunda voz) de cada pie; thirds = secciones con segunda voz.
# levels = volumen de cada parte respecto de la melodía (dB, por RMS).
SONGS = {
    "cueca_del_emboque": dict(
        music=EMBOQUE, key=67, eighth=0.165, style="campesina", seed=11,
        pies=[("arpa", "arpa"), ("acordeon", "arpa")],
        thirds=[SECTIONS[2:], SECTIONS],
        reverb=0.16,
        levels=dict(lead=0, second=-5, guitarra=-8, bajo=-8, pandero=-15, parche=-19,
                    madera=-17, palmas=-17),
    ),
    "cueca_brava_del_puerto": dict(
        music=PUERTO, key=74, eighth=0.148, style="brava", seed=23,
        pies=[("piano", "piano"), ("acordeon", "piano")],
        thirds=[SECTIONS[2:], SECTIONS],
        reverb=0.12,
        levels=dict(lead=0, second=-6, guitarra=-10, piano_mi=-8, pandero=-14,
                    parche=-19, madera=-16, palmas=-16),
    ),
    "cueca_nortina_de_la_sopaipilla": dict(
        music=SOPAIPILLA, key=70, eighth=0.158, style="nortina", seed=37,
        pies=[("trompeta", "trompeta"), ("trompeta", "trombon")],
        thirds=[SECTIONS, SECTIONS],
        reverb=0.08,
        levels=dict(lead=0, second=-4, bronces=-9, tuba=-6, bombo=-11, caja=-15,
                    platillo=-17),
    ),
    "cueca_chilota_de_los_dos": dict(
        music=CHILOTA, key=69, eighth=0.178, style="chilota", seed=52,
        pies=[("acordeon", "acordeon"), ("violin", "acordeon")],
        thirds=[SECTIONS[2:], SECTIONS],
        reverb=0.17,
        levels=dict(lead=0, second=-5, guitarra=-8, bajo=-9, bombo=-12),
    ),
}

# --- Lectura de la partitura --------------------------------------------------------

TOKEN = re.compile(r"^(r|([#b]?)([1-7])(['\,]*))(?::(\d+))?$")


def parse_melody(text, name):
    """Lista de compases; cada nota = (inicio en corcheas, duración, grado, octava,
    alteración), con grado None para un silencio."""
    bars = []
    for i, bar in enumerate(text.split("|")):
        notes = []
        pos = 0
        for tok in bar.split():
            m = TOKEN.match(tok)
            if not m:
                raise ValueError("%s: compás %d: no entiendo '%s'" % (name, i + 1, tok))
            dur = int(m.group(5) or 1)
            if m.group(1) == "r":
                notes.append((pos, dur, None, 0, 0))
            else:
                acc = {"": 0, "#": 1, "b": -1}[m.group(2)]
                octv = m.group(4).count("'") - m.group(4).count(",")
                notes.append((pos, dur, int(m.group(3)), octv, acc))
            pos += dur
        if pos != BAR:
            raise ValueError("%s: el compás %d suma %d corcheas" % (name, i + 1, pos))
        bars.append(notes)
    return bars


def degree_semitones(deg, octv, acc):
    return MAJOR[deg - 1] + 12 * octv + acc


def second_voice(deg, octv, acc, chord, strong):
    """Semitonos de la segunda voz del dúo: la tercera diatónica de abajo; en tiempo
    fuerte o nota larga, si esa tercera no es del acorde, la nota del acorde más
    cercana bajo la melodía (al menos una tercera menor más abajo)."""
    d, o = deg - 2, octv
    if d < 1:
        d += 7
        o -= 1
    third = degree_semitones(d, o, 0)
    pcs = {s % 12 for s in CHORDS[chord]}
    if not strong or third % 12 in pcs:
        return third
    top = degree_semitones(deg, octv, acc)
    return max(s for s in range(top - 9, top - 2) if s % 12 in pcs)


# --- Arreglo: las notas de cada parte -----------------------------------------------


class Score:
    """Notas por parte: parts[(rol, instrumento)] = [(t, dur, midi, vel)]."""

    def __init__(self, eighth, rng):
        self.eighth = eighth
        self.rng = rng
        self.parts = {}

    def note(self, role, inst, t8, dur8, midi, vel, jitter=0.006, len_s=None):
        t = t8 * self.eighth + self.rng.uniform(-jitter, jitter)
        dur = len_s if len_s is not None else dur8 * self.eighth
        vel = int(np.clip(vel + self.rng.integers(-5, 6), 1, 127))
        self.parts.setdefault((role, inst), []).append((max(t, 0.0), dur, int(midi), vel))

    def drum(self, role, t8, vel, note=None, jitter=0.004):
        self.note(role, "bateria", t8, 0.5, note or DRUM[role], vel, jitter)


def is_34(bar_index):
    """Compás del acompañamiento: alterna 6/8 y 3/4 (sesquiáltera)."""
    return bar_index % 2 == 1


def chord_midis(key, chord, lo, hi):
    pcs = {(key + s) % 12 for s in CHORDS[chord]}
    return [m for m in range(lo, hi + 1) if m % 12 in pcs]


def bass_note(key, chord, fifth=False, lo=40):
    pc = (key + CHORDS[chord][0] + (7 if fifth else 0)) % 12
    return lo + (pc - lo) % 12


def guitar_voicing(key, chord):
    """Seis cuerdas: el bajo en la fundamental y el resto abierto hacia arriba."""
    bass = bass_note(key, chord, lo=40)
    pcs = {(key + s) % 12 for s in CHORDS[chord]}
    notes = [bass]
    m = bass + 7
    while len(notes) < 6 and m <= 68:
        if m % 12 in pcs:
            notes.append(m)
        m += 1
    return notes


def strum(sc, bar8, step, notes, kind, vel, ring):
    """Un golpe de guitarra: abajo (D, grave → agudo), arriba (U, solo las agudas) o
    apagado (M, el "chasquido" de la cueca: la mano mata las cuerdas)."""
    if kind == "U":
        notes = list(reversed(notes[-4:]))
        vel -= 25
    gap = 0.009 if kind != "U" else 0.007
    t8 = bar8 + step
    for i, m in enumerate(notes):
        dt8 = i * gap / sc.eighth
        if kind == "M":
            sc.note("guitarra", "guitarra", t8 + dt8, 0, m, vel, len_s=0.045)
        else:
            sc.note("guitarra", "guitarra", t8 + dt8, ring, m, vel - i * 2)


def guitar_bar(sc, bar8, key, chord, b, intensity=1.0):
    notes = guitar_voicing(key, chord)
    if is_34(b):
        pattern = [(0, "D", 100, 1.1), (1, "U", 75, 1.0), (2, "D", 88, 1.1),
                   (3, "U", 75, 1.0), (4, "D", 88, 1.1), (5, "U", 75, 1.0)]
    else:
        pattern = [(0, "D", 100, 1.1), (1, "U", 75, 1.0), (2, "D", 78, 1.0),
                   (3, "M", 100, 0), (4, "U", 75, 1.0), (5, "D", 78, 1.0)]
    for step, kind, vel, ring in pattern:
        strum(sc, bar8, step, notes, kind, int(vel * intensity), ring)


def bass_bar(sc, role, inst, bar8, key, chord, b, lo=40, vel=95, short=False):
    """Bajo de fundamental y quinta (bordoneo): 6/8 en 1 y 4; 3/4 en 1, 3 y 5."""
    if is_34(b):
        hits = [(0, False, 2), (2, True, 2), (4, False, 2)]
    else:
        hits = [(0, False, 3), (3, True, 3)]
    root = bass_note(key, chord, False, lo)
    for step, fifth, dur in hits:
        m = root - 5 if fifth else root  # la quinta, abajo de la fundamental
        if m < lo - 6:
            m += 12
        sc.note(role, inst, bar8 + step, 0.9 if short else dur, m,
                vel if step == 0 else vel - 12)


def piano_left_bar(sc, bar8, key, chord, b):
    """Mano izquierda del piano chilenero: bajo y acorde (oom-pa)."""
    chord_notes = chord_midis(key, chord, 53, 65)[:3]
    plan = [(0, "b"), (2, "c"), (4, "c")] if is_34(b) else [(0, "b"), (2, "c"), (3, "q"), (5, "c")]
    for step, what in plan:
        if what == "c":
            for m in chord_notes:
                sc.note("piano_mi", "piano", bar8 + step, 0.9, m, 62)
        else:
            m = bass_note(key, chord, False, 38)
            sc.note("piano_mi", "piano", bar8 + step, 1.8, m - 5 if what == "q" else m, 88)


def brass_bar(sc, bar8, key, chord, b):
    """Banda de bronces: trombones a contratiempo y tuba en el bajo."""
    chord_notes = chord_midis(key, chord, 55, 67)[:3]
    for step in ([1, 3, 5] if is_34(b) else [1, 2, 4, 5]):
        for m in chord_notes:
            sc.note("bronces", "trombon", bar8 + step, 0.7, m, 70)
    bass_bar(sc, "tuba", "tuba", bar8, key, chord, b, lo=34, vel=100, short=True)


def pandero_bar(sc, bar8, b):
    vels = [100, 50, 85, 50, 85, 50] if is_34(b) else [100, 50, 62, 92, 50, 62]
    for step, v in enumerate(vels):
        sc.drum("pandero", bar8 + step, v)
    for step in ([0, 2, 4] if is_34(b) else [0, 3]):
        sc.drum("parche", bar8 + step, 80 if step == 0 else 62)


def madera_bar(sc, bar8, note):
    """Tamboreo (golpes en la caja del arpa) o tormento: siempre en 3/4."""
    for step, v in [(0, 95), (2, 70), (4, 78)]:
        sc.drum("madera", bar8 + step, v, note=note)


def palmas_bar(sc, bar8, b):
    for step, v in ([(0, 100), (2, 80), (4, 80)] if is_34(b) else [(0, 100), (3, 85)]):
        sc.drum("palmas", bar8 + step, v)


def banda_bar(sc, bar8, b, last=False, first=False):
    """Bombo, caja y platillos de la banda nortina."""
    if is_34(b):
        bombo = [(0, 112), (2, 82), (4, 82)]
        caja = [100, 45, 85, 45, 85, 45]
    else:
        bombo = [(0, 112), (3, 95)]
        caja = [100, 45, 55, 90, 45, 55]
    for step, v in bombo:
        sc.drum("bombo", bar8 + step, v)
    for step, v in enumerate(caja):
        if last and step >= 4:
            if step == 4:
                for k in range(8):  # redoble al final de la sección
                    sc.drum("caja", bar8 + 4 + k * 0.25, 55 + 7 * k)
        else:
            sc.drum("caja", bar8 + step, v)
    if first:
        sc.drum("platillo", bar8, 92)
    elif not is_34(b):
        sc.drum("platillo", bar8 + 3, 48)


def bombo_chilote_bar(sc, bar8, b):
    hits = [(0, 105), (2, 60), (4, 75)] if is_34(b) else [(0, 105), (3, 85), (5, 55)]
    for step, v in hits:
        sc.drum("bombo", bar8 + step, v)


def accompany(sc, style, bar8, key, chord, b, section, bar_in_section, n_bars):
    last = bar_in_section == n_bars - 1
    first = bar_in_section == 0
    entrada = section == "entrada"
    lively = section.startswith("seguidilla") or section == "remate"
    if style == "campesina":
        guitar_bar(sc, bar8, key, chord, b)
        bass_bar(sc, "bajo", "arpa", bar8, key, chord, b, lo=43, vel=92)
        pandero_bar(sc, bar8, b)
        madera_bar(sc, bar8, DRUM["madera"])
        if lively:
            palmas_bar(sc, bar8, b)
    elif style == "brava":
        guitar_bar(sc, bar8, key, chord, b, intensity=0.9)
        piano_left_bar(sc, bar8, key, chord, b)
        pandero_bar(sc, bar8, b)
        madera_bar(sc, bar8, DRUM["madera_aguda"])
        if lively:
            palmas_bar(sc, bar8, b)
    elif style == "nortina":
        if entrada:
            bass_bar(sc, "tuba", "tuba", bar8, key, chord, b, lo=34, vel=100, short=True)
        else:
            brass_bar(sc, bar8, key, chord, b)
        banda_bar(sc, bar8, b, last=last, first=first and not entrada)
    elif style == "chilota":
        guitar_bar(sc, bar8, key, chord, b, intensity=0.85)
        bass_bar(sc, "bajo", "guitarra", bar8, key, chord, b, lo=40, vel=85)
        bombo_chilote_bar(sc, bar8, b)


def melody_velocity(pos):
    return 100 if pos == 0 else 90 if pos == 3 else 80


SUSTAINED = ("acordeon", "violin", "trompeta", "trombon")


def compose(spec):
    rng = np.random.default_rng(spec["seed"])
    eighth = spec["eighth"]
    sc = Score(eighth, rng)
    key = spec["key"]
    style = spec["style"]
    music = {}
    for s in SECTIONS:
        chords = spec["music"][s][0].split()
        bars = parse_melody(spec["music"][s][1], s)
        if len(chords) != len(bars):
            raise ValueError("%s: %d acordes para %d compases" % (s, len(chords), len(bars)))
        music[s] = (chords, bars)

    bar = 0
    # Entrada: dos compases solo de ritmo (la guitarra o la banda "llaman").
    for i in range(2):
        accompany(sc, style, bar * BAR, key, "I", bar, "entrada", i, 2)
        bar += 1

    for pie, (lead, second) in enumerate(spec["pies"]):
        for section in SECTIONS:
            chords, bars = music[section]
            for i, (chord, notes) in enumerate(zip(chords, bars)):
                b8 = bar * BAR
                # Si la melodía toca la séptima (el grado 4) sobre el V, el acorde es V7.
                if chord == "V" and any(n[2] == 4 and n[4] == 0 for n in notes):
                    chord = "V7"
                accompany(sc, style, b8, key, chord, bar, section, i, len(bars))
                for pos, dur, deg, octv, acc in notes:
                    if deg is None:
                        continue
                    vel = melody_velocity(pos)
                    length = dur * 0.97 if lead in SUSTAINED else dur
                    sc.note("lead", lead, b8 + pos, length,
                            key + INSTRUMENTS[lead][2] * 12 + degree_semitones(deg, octv, acc), vel)
                    if section in spec["thirds"][pie]:
                        strong = pos in (0, 3) or dur >= 3
                        length2 = dur * 0.97 if second in SUSTAINED else dur
                        sc.note("second", second, b8 + pos, length2,
                                key + INSTRUMENTS[second][2] * 12
                                + second_voice(deg, octv, acc, chord, strong), vel - 8)
                bar += 1

    # Acorde final: todos juntos en la tónica.
    b8 = bar * BAR
    lead, second = spec["pies"][-1]
    sc.note("lead", lead, b8, 2.2 / eighth, key + INSTRUMENTS[lead][2] * 12, 100)
    sc.note("second", second, b8, 2.2 / eighth, key + INSTRUMENTS[second][2] * 12 - 5, 92)
    if style == "nortina":
        for m in chord_midis(key, "I", 55, 67)[:3]:
            sc.note("bronces", "trombon", b8, 2.2 / eighth, m, 90)
        sc.note("tuba", "tuba", b8, 2.2 / eighth, bass_note(key, "I", lo=34), 105)
        sc.drum("bombo", b8, 120)
        sc.drum("platillo", b8, 110)
    else:
        strum(sc, b8, 0, guitar_voicing(key, "I"), "D", 105, 2.5 / eighth)
        role, inst, lo = {"campesina": ("bajo", "arpa", 43), "brava": ("piano_mi", "piano", 38),
                          "chilota": ("bajo", "guitarra", 40)}[style]
        sc.note(role, inst, b8, 2.5 / eighth, bass_note(key, "I", lo=lo), 100)
        sc.drum("bombo" if style == "chilota" else "parche", b8, 110)
    total = b8 * eighth + 4.0
    return sc, total


# --- Grabación ----------------------------------------------------------------------


def ensure_soundfont():
    if os.path.exists(SF2_PATH):
        return SF2_PATH
    os.makedirs(os.path.dirname(SF2_PATH), exist_ok=True)
    print("Descargando GeneralUser GS (32 MB) en", SF2_PATH)
    urllib.request.urlretrieve(SF2_URL, SF2_PATH + ".part")
    os.replace(SF2_PATH + ".part", SF2_PATH)
    return SF2_PATH


def render_part(sf2, inst, notes, total):
    """Graba una parte con su instrumento; devuelve audio estéreo (n, 2)."""
    synth = tinysoundfont.Synth(samplerate=SR)
    sfid = synth.sfload(sf2)
    if inst == "bateria":
        synth.program_select(0, sfid, 128, 0, is_drums=True)
    else:
        bank, preset, _ = INSTRUMENTS[inst]
        synth.program_select(0, sfid, bank, preset)
    events = []
    for t, dur, midi, vel in notes:
        events.append((int(t * SR), 1, midi, vel))
        events.append((int((t + max(dur, 0.03)) * SR), 0, midi, 0))
    events.sort(key=lambda e: (e[0], e[1]))  # noteoff antes que noteon en el mismo instante
    n = int(total * SR)
    out = np.zeros((n, 2), dtype=np.float32)
    pos = 0
    for when, on, midi, vel in events + [(n, -1, 0, 0)]:
        when = min(when, n)
        if when > pos:
            buf = synth.generate_simple(when - pos)
            out[pos:when] = np.frombuffer(buf, dtype=np.float32).reshape(-1, 2)
            pos = when
        if on == 1:
            synth.noteon(0, midi, vel)
        elif on == 0:
            synth.noteoff(0, midi)
    return out.astype(np.float64)


def active_rms(x):
    """RMS de los tramos donde la parte suena (las palmas solo están en la seguidilla)."""
    mono = np.mean(x, axis=1)
    frame = 4096
    k = len(mono) // frame
    fr = np.sqrt(np.mean(mono[: k * frame].reshape(k, frame) ** 2, axis=1))
    loud = fr[fr > fr.max() * 0.05]
    return float(np.sqrt(np.mean(loud ** 2))) if len(loud) else 1e-9


PAN = {"lead": 0.0, "second": -0.25, "guitarra": 0.3, "bajo": -0.1, "piano_mi": -0.2,
       "pandero": 0.35, "parche": 0.2, "madera": -0.4, "palmas": 0.15, "bronces": -0.3,
       "tuba": 0.0, "bombo": 0.0, "caja": 0.25, "platillo": -0.2}


def fft_filter(x, lo=None, hi=None):
    n = len(x)
    size = 1 << int(np.ceil(np.log2(n)))
    spec = np.fft.rfft(x, size)
    f = np.fft.rfftfreq(size, 1 / SR)
    g = np.ones_like(f)
    if lo:
        g *= 1 / (1 + (lo / np.maximum(f, 1e-3)) ** 4)
    if hi:
        g *= 1 / (1 + (f / hi) ** 4)
    return np.fft.irfft(spec * g, size)[:n]


def reverb(x, rng, wet, seconds=1.8, decay=0.45):
    """Sala: convolución con ruido que se apaga (el efecto va horneado en el archivo;
    en la web los efectos de bus pueden no aplicarse)."""
    n = int(seconds * SR)
    t = np.arange(n) / SR
    ir = rng.uniform(-1, 1, n) * np.exp(-t / decay)
    ir[: int(0.02 * SR)] = 0
    ir = fft_filter(ir, 300, 6000)
    ir /= np.sqrt(np.sum(ir ** 2))
    size = 1 << int(np.ceil(np.log2(len(x) + n)))
    y = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[: len(x)]
    return x + wet * y


def render(spec, sf2):
    sc, total = compose(spec)
    levels = spec["levels"]
    stems = [(role, inst, render_part(sf2, inst, notes, total))
             for (role, inst), notes in sc.parts.items()]
    # Volumen de cada parte relativo a la melodía (por RMS), así la mezcla no depende
    # de lo fuerte que venga cada muestra del SoundFont.
    lead_rms = np.mean([active_rms(a) for r, _, a in stems if r == "lead"])
    mix = np.zeros((int(total * SR), 2))
    for role, inst, audio in stems:
        g = lead_rms * 10 ** (levels.get(role, -12) / 20) / active_rms(audio)
        a = (PAN.get(role, 0.0) + 1) * np.pi / 4
        mix += audio * g * np.array([np.cos(a), np.sin(a)]) * np.sqrt(2)
    rng = np.random.default_rng(spec["seed"] + 1)
    left = fft_filter(reverb(mix[:, 0], rng, spec["reverb"]), 55, None)
    right = fft_filter(reverb(mix[:, 1], rng, spec["reverb"]), 55, None)
    st = np.stack([left, right], axis=1)
    # Masterización: volumen parejo entre canciones (RMS -17 dBFS, pico -1 dB).
    st *= 10 ** (-17.0 / 20) / np.sqrt(np.mean(st ** 2))
    st = np.tanh(st * 1.1) / np.tanh(1.1)  # limitador suave para los golpes
    st *= min(10 ** (-17.0 / 20) / np.sqrt(np.mean(st ** 2)),
              10 ** (-1.0 / 20) / max(np.max(np.abs(st)), 1e-9))
    fade = int(1.5 * SR)
    st[-fade:] *= np.linspace(1, 0, fade)[:, None]
    return st


def write_mp3(name, st):
    os.makedirs(OUT_DIR, exist_ok=True)
    data = (np.clip(st, -1, 1) * 32767).astype("<i2")
    with tempfile.TemporaryDirectory() as tmp:
        wav_path = os.path.join(tmp, name + ".wav")
        with wave.open(wav_path, "wb") as w:
            w.setnchannels(2)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(data.tobytes())
        out = os.path.join(OUT_DIR, name + ".mp3")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path,
                        "-c:a", "libmp3lame", "-b:a", "128k", out], check=True)
    rms = 20 * np.log10(np.sqrt(np.mean(st ** 2)))
    print("    %.0f s, RMS %.1f dBFS" % (len(st) / SR, rms))


if __name__ == "__main__":
    wanted = set(sys.argv[1:])
    unknown = wanted - set(SONGS)
    if unknown:
        sys.exit("No existe: %s (hay: %s)" % (", ".join(sorted(unknown)), ", ".join(SONGS)))
    sf2 = ensure_soundfont()
    print("Grabando cuecas en", os.path.normpath(OUT_DIR))
    for song, spec in SONGS.items():
        if not wanted or song in wanted:
            print(" ", song)
            write_mp3(song, render(spec, sf2))
