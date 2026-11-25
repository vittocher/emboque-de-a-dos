"""Arte PROVISORIO del Tue Tue (jefe final), dibujado por código hasta que llegue
el definitivo. Hay dos diseños:

- "cabeza" (el que se usa): el Tue Tue transformado del video de la intro, una
  cabeza verde que vuela con orejas de murciélago, cejas blancas, nariz grande,
  boca con cuatro dientes, un chichón con pelos. Estilo papel recortado (como el
  video): formas planas con borde irregular, grano de papel y sombra suave.
  Escribe en assets/enemigos/tue_tue/:
    vuelo_1..3.png  aleteo de las orejas (arriba, al medio, abajo)
    grito.png       chillando (boca abierta con lengua, cejas enojadas): aviso de un ataque
    trozo.png       trocito de papel verde (partículas al pegarle)
    vida.png        cabecita: una vida en la barra del HUD
- "pájaro" (el primero, guardado por si se vuelve a él): pájaro nocturno de ojos
  amarillos. Escribe en assets/enemigos/tue_tue/alternativos/pajaro/ (vuelo_1..3,
  grito, pluma, vida).
Los dos comparten estrella.png (mareado). En el juego se elige el diseño con
"look" en el Inspector del TueTue (scenes/boss/tue_tue.tscn).

Uso (desde la raíz del proyecto):  python3 tools/generate_tuetue_art.py
Requiere Pillow y numpy. Para el arte definitivo basta con reemplazar los PNG
(mismo nombre); se dibujan de frente, centrados en la cabeza.
"""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "enemigos", "tue_tue")
OUT_PAJARO = os.path.join(OUT, "alternativos", "pajaro")
S = 4                      # supermuestreo
W, H = 360, 280            # tamaño final de cada cuadro
CX, CY = 180, 150          # centro del cuerpo

OUTLINE = (22, 13, 30, 255)
WING_DARK = (38, 26, 66, 255)
WING_LIGHT = (78, 58, 122, 255)
BODY = (56, 36, 80, 255)
HEAD = (64, 42, 90, 255)
BELLY = (96, 70, 118, 255)
FACE = (88, 62, 112, 255)
EYE = (255, 206, 64, 255)
EYE_RING = (226, 120, 30, 255)
PUPIL = (96, 8, 22, 255)
BEAK = (222, 170, 72, 255)
BEAK_DARK = (150, 98, 40, 255)


def sc(p):
    return (p[0] * S, p[1] * S)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


def feather(d, pivot, angle, length, width, color, outline=OUTLINE, ow=3):
    """Pluma: un huso desde el pivote en la dirección angle (grados)."""
    a = math.radians(angle)
    ux, uy = math.cos(a), math.sin(a)
    nx, ny = -uy, ux
    pts = []
    steps = 14
    for i in range(steps + 1):
        t = i / steps
        w = width * math.sin(math.pi * t) ** 0.8
        pts.append((pivot[0] + ux * length * t + nx * w, pivot[1] + uy * length * t + ny * w))
    for i in range(steps, -1, -1):
        t = i / steps
        w = width * math.sin(math.pi * t) ** 0.8
        pts.append((pivot[0] + ux * length * t - nx * w, pivot[1] + uy * length * t - ny * w))
    big = [(pivot[0] + (x - pivot[0]) * 1.0 + 0, pivot[1] + (y - pivot[1]) * 1.0) for x, y in pts]
    d.polygon([sc(p) for p in big], fill=outline)
    # Relleno un poco más chico (deja ver el contorno).
    inner = []
    cx = sum(x for x, _ in pts) / len(pts)
    cy = sum(y for _, y in pts) / len(pts)
    for x, y in pts:
        dx, dy = x - cx, y - cy
        dist = math.hypot(dx, dy) or 1
        inner.append((x - dx / dist * ow * 0.8, y - dy / dist * ow * 0.8))
    d.polygon([sc(p) for p in inner], fill=color)


def wing(d, side, lift):
    """Ala de plumas en abanico. side = -1 izquierda / 1 derecha; lift 1 = arriba, -1 = abajo."""
    pivot = (CX + side * 34, CY - 18)
    # Ángulo central del abanico (grados en pantalla, 0 = derecha, 90 = abajo).
    base = -35 - 40 * lift if side > 0 else 180 + 35 + 40 * lift
    n = 7
    for i in range(n):
        t = i / (n - 1)
        spread = (t - 0.5) * 70
        ang = base + side * spread
        length = 118 - abs(t - 0.35) * 70
        color = lerp(WING_LIGHT, WING_DARK, t)
        feather(d, pivot, ang, length, 15 - t * 4, color)
    # Hombro (cubre el nacimiento de las plumas).
    r = 26
    d.ellipse([sc((pivot[0] - r, pivot[1] - r)), sc((pivot[0] + r, pivot[1] + r))], fill=OUTLINE)
    r2 = 22
    d.ellipse([sc((pivot[0] - r2, pivot[1] - r2)), sc((pivot[0] + r2, pivot[1] + r2))], fill=WING_DARK)


def ellipse(d, box, fill, ow=3):
    (x0, y0), (x1, y1) = box
    d.ellipse([sc((x0 - ow, y0 - ow)), sc((x1 + ow, y1 + ow))], fill=OUTLINE)
    d.ellipse([sc((x0, y0)), sc((x1, y1))], fill=fill)


def polygon(d, pts, fill, ow=3):
    cx = sum(x for x, _ in pts) / len(pts)
    cy = sum(y for _, y in pts) / len(pts)
    big = []
    for x, y in pts:
        dx, dy = x - cx, y - cy
        dist = math.hypot(dx, dy) or 1
        big.append((x + dx / dist * ow, y + dy / dist * ow))
    d.polygon([sc(p) for p in big], fill=OUTLINE)
    d.polygon([sc(p) for p in pts], fill=fill)


def bird(lift, screech=False):
    img = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    wing(d, -1, lift)
    wing(d, 1, lift)
    # Garras colgando.
    for side in (-1, 1):
        x = CX + side * 16
        polygon(d, [(x - 5, CY + 55), (x + 5, CY + 55), (x + 3, CY + 78), (x - 3, CY + 78)], BEAK_DARK, 2)
        for k in (-1, 0, 1):
            polygon(d, [(x + k * 5 - 2, CY + 76), (x + k * 5 + 2, CY + 76), (x + k * 7, CY + 88)], BEAK_DARK, 2)
    # Cuerpo y pecho con plumas en escamas.
    ellipse(d, ((CX - 50, CY - 40), (CX + 50, CY + 66)), BODY)
    ellipse(d, ((CX - 32, CY - 6), (CX + 32, CY + 60)), BELLY, 0)
    for row in range(4):
        y = CY + 4 + row * 13
        for k in range(-2, 3):
            x = CX + k * 12 + (6 if row % 2 else 0)
            if abs(x - CX) > 26 - row * 2:
                continue
            d.arc([sc((x - 7, y - 6)), sc((x + 7, y + 6))], 20, 160, fill=BODY, width=2 * S)
    # Penachos (orejas de plumas).
    for side in (-1, 1):
        polygon(d, [(CX + side * 20, CY - 78), (CX + side * 58, CY - 128), (CX + side * 44, CY - 70)], HEAD)
        polygon(d, [(CX + side * 30, CY - 82), (CX + side * 50, CY - 112), (CX + side * 42, CY - 78)], WING_LIGHT, 0)
    # Cabeza y disco de la cara.
    ellipse(d, ((CX - 56, CY - 100), (CX + 56, CY - 2)), HEAD)
    ellipse(d, ((CX - 46, CY - 82), (CX + 46, CY - 18)), FACE, 0)
    # Ojos enormes.
    eye_col = (255, 96, 60, 255) if screech else EYE
    for side in (-1, 1):
        ex, ey = CX + side * 22, CY - 52
        ellipse(d, ((ex - 19, ey - 19), (ex + 19, ey + 19)), EYE_RING)
        d.ellipse([sc((ex - 15, ey - 15)), sc((ex + 15, ey + 15))], fill=eye_col)
        pr = 9 if not screech else 6
        d.ellipse([sc((ex - pr + side * -2, ey - pr + 1)), sc((ex + pr + side * -2, ey + pr + 1))], fill=PUPIL)
        d.ellipse([sc((ex - 9, ey - 10)), sc((ex - 3, ey - 4))], fill=(255, 250, 230, 255))
        # Ceja enojada.
        # (el extremo de adentro más bajo: cara de enojo).
        polygon(d, [(ex + side * 22, ey - 31), (ex - side * 18, ey - 18), (ex - side * 18, ey - 11),
                    (ex + side * 22, ey - 24)], OUTLINE, 0)
    # Pico ganchudo (abierto al chillar).
    if screech:
        polygon(d, [(CX - 11, CY - 34), (CX + 11, CY - 34), (CX, CY - 22)], BEAK)
        polygon(d, [(CX - 8, CY - 16), (CX + 8, CY - 16), (CX, CY - 4)], BEAK_DARK)
        d.polygon([sc((CX - 7, CY - 22)), sc((CX + 7, CY - 22)), sc((CX, CY - 15))], fill=(120, 20, 30, 255))
    else:
        polygon(d, [(CX - 11, CY - 34), (CX + 11, CY - 34), (CX + 3, CY - 14), (CX, CY - 10)], BEAK)
        d.polygon([sc((CX - 2, CY - 18)), sc((CX + 3, CY - 14)), sc((CX, CY - 10))], fill=BEAK_DARK)
    img = img.resize((W, H), Image.LANCZOS)
    # Sombra suave alrededor (se lee sobre el fondo azul).
    alpha = img.split()[3]
    glow = Image.new("RGBA", img.size, (10, 4, 18, 0))
    glow.putalpha(alpha.filter(ImageFilter.GaussianBlur(5)).point(lambda a: int(a * 0.55)))
    out = Image.alpha_composite(glow, img)
    return out


def pluma():
    img = Image.new("RGBA", (40 * S, 40 * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def fsc(p):
        return (p[0] * S, p[1] * S)

    pts = []
    for i in range(15):
        t = i / 14
        w = 7 * math.sin(math.pi * t)
        pts.append((6 + 28 * t, 20 - w))
    for i in range(14, -1, -1):
        t = i / 14
        w = 7 * math.sin(math.pi * t)
        pts.append((6 + 28 * t, 20 + w))
    d.polygon([fsc(p) for p in pts], fill=WING_LIGHT, outline=OUTLINE)
    d.line([fsc((4, 20)), fsc((34, 20))], fill=OUTLINE, width=2 * S)
    return img.resize((40, 40), Image.LANCZOS)


def vida_pajaro():
    """Pluma dorada con contorno oscuro (se lee sobre la placa de madera)."""
    n = 48
    img = Image.new("RGBA", (n * S, n * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def fsc(p):
        return (p[0] * S, p[1] * S)

    def huso(w, grow):
        pts = []
        for i in range(17):
            t = i / 16
            r = w * math.sin(math.pi * t) ** 0.7 + grow
            pts.append((6 - grow + (36 + 2 * grow) * t, 24 - r))
        for i in range(16, -1, -1):
            t = i / 16
            r = w * math.sin(math.pi * t) ** 0.7 + grow
            pts.append((6 - grow + (36 + 2 * grow) * t, 24 + r))
        return [fsc(p) for p in pts]

    d.polygon(huso(9, 2.5), fill=OUTLINE)
    d.polygon(huso(9, 0), fill=(255, 214, 92, 255))
    d.polygon(huso(5, 0)[:17] + [fsc((42, 24))], fill=(255, 240, 170, 255))
    d.line([fsc((3, 24)), fsc((40, 24))], fill=(150, 96, 30, 255), width=2 * S)
    for k in range(4):
        x = 14 + k * 7
        d.line([fsc((x, 24)), fsc((x + 5, 17))], fill=(196, 132, 40, 255), width=S)
        d.line([fsc((x, 24)), fsc((x + 5, 31))], fill=(196, 132, 40, 255), width=S)
    img = img.rotate(35, resample=Image.BICUBIC)
    return img.resize((n, n), Image.LANCZOS)


def estrella():
    img = Image.new("RGBA", (32 * S, 32 * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pts = []
    for i in range(10):
        r = 15 if i % 2 == 0 else 6.5
        a = math.radians(-90 + i * 36)
        pts.append(((16 + r * math.cos(a)) * S, (16 + r * math.sin(a)) * S))
    d.polygon(pts, fill=(255, 222, 90, 255), outline=(150, 100, 20, 255))
    return img.resize((32, 32), Image.LANCZOS)


# ---------------------------------------------------------------------------
# Diseño "cabeza": el Tue Tue transformado (papel recortado)
# ---------------------------------------------------------------------------

HW, HH = 640, 380          # cuadro final
HS = 2                     # supersampleo
HC = (320, 200)            # centro de la cabeza en el cuadro

GREEN = (125, 163, 122)
GREEN_DARK = (106, 144, 104)
GREEN_EAR = (122, 160, 119)
NOSE = (108, 148, 106)
PINK = (182, 138, 128)
VEIN = (148, 96, 90)
WHITE = (232, 236, 232)
PUPIL = (176, 178, 176)
MOUTH = (38, 16, 12)
TEETH = (214, 228, 212)
TONGUE = (214, 112, 112)
BROW = (222, 230, 228)
WHISKER = (214, 220, 220)

_rng = np.random.default_rng(7)


def _resample(points, n):
    """Puntos equiespaciados a lo largo de un contorno cerrado."""
    pts = np.array(points + [points[0]], dtype=float)
    seg = np.linalg.norm(np.diff(pts, axis=0), axis=1)
    cum = np.concatenate([[0], np.cumsum(seg)])
    out = []
    for t in np.linspace(0, cum[-1], n, endpoint=False):
        i = np.searchsorted(cum, t, side="right") - 1
        f = (t - cum[i]) / max(seg[i], 1e-6)
        out.append(pts[i] + (pts[i + 1] - pts[i]) * f)
    return np.array(out)


def wobble(points, amp=2.0, seed=0, n=220):
    """Contorno de papel recortado a mano: se remuestrea y se ondula de a poco."""
    pts = _resample(points, n)
    rng = np.random.default_rng(seed)
    t = np.linspace(0, 2 * np.pi, n, endpoint=False)
    off = np.zeros(n)
    for f in (3, 7, 13, 23):
        off += np.sin(t * f + rng.uniform(0, 6.28)) * amp / (f ** 0.5)
    nxt = np.roll(pts, -1, axis=0)
    prv = np.roll(pts, 1, axis=0)
    tang = nxt - prv
    nrm = np.stack([tang[:, 1], -tang[:, 0]], axis=1)
    nrm /= np.maximum(np.linalg.norm(nrm, axis=1, keepdims=True), 1e-6)
    return [tuple(p) for p in pts + nrm * off[:, None]]


def _mask(polys, ellipses=()):
    m = Image.new("L", (HW * HS, HH * HS), 0)
    d = ImageDraw.Draw(m)
    for poly in polys:
        d.polygon([(x * HS, y * HS) for x, y in poly], fill=255)
    for (x0, y0, x1, y1) in ellipses:
        d.ellipse([x0 * HS, y0 * HS, x1 * HS, y1 * HS], fill=255)
    return m


_GRAIN = None


def _grain():
    """Grano de papel (fino + manchas suaves), un solo mapa para todo el dibujo."""
    global _GRAIN
    if _GRAIN is None:
        w, h = HW * HS, HH * HS
        fine = Image.fromarray(((_rng.normal(0, 1, (h, w)) * 40) + 128).clip(0, 255).astype(np.uint8))
        fine = np.asarray(fine.filter(ImageFilter.GaussianBlur(1.1)), dtype=float) / 128.0 - 1.0
        blot = Image.fromarray(((_rng.normal(0, 1, (h // 8, w // 8)) * 60) + 128).clip(0, 255).astype(np.uint8))
        blot = blot.resize((w, h), Image.BICUBIC).filter(ImageFilter.GaussianBlur(10))
        blot = np.asarray(blot, dtype=float) / 128.0 - 1.0
        _GRAIN = fine * 0.10 + blot * 0.10
    return _GRAIN


def paper(mask, color, edge=0.14, grain=1.0):
    """Capa de papel del color dado: grano, borde un poco más oscuro (como el corte)."""
    m = np.asarray(mask, dtype=float) / 255.0
    inner = np.asarray(mask.filter(ImageFilter.GaussianBlur(4 * HS)), dtype=float) / 255.0
    shade = 1.0 + _grain() * grain - edge * (1.0 - inner).clip(0, 1) * 2.0
    rgb = np.stack([np.full(m.shape, c, dtype=float) for c in color], axis=2) * shade[:, :, None]
    out = np.dstack([rgb.clip(0, 255), m * 255]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def shadow(mask, offset=(3, 4), blur=4, alpha=0.38):
    """Sombra del recorte sobre lo de atrás."""
    sh = Image.new("L", mask.size, 0)
    sh.paste(mask, (offset[0] * HS, offset[1] * HS))
    sh = sh.filter(ImageFilter.GaussianBlur(blur * HS)).point(lambda a: int(a * alpha))
    layer = Image.new("RGBA", mask.size, (12, 18, 14, 0))
    layer.putalpha(sh)
    return layer


def _rot(points, ang, origin):
    a = math.radians(ang)
    c, s_ = math.cos(a), math.sin(a)
    ox, oy = origin
    return [(ox + (x - ox) * c - (y - oy) * s_, oy + (x - ox) * s_ + (y - oy) * c) for x, y in points]


def _place(points, side, origin):
    """Puntos de la oreja derecha (locales) → oreja del lado [side] en el cuadro."""
    ox, oy = origin
    return [(ox + side * x, oy + y) for x, y in points]


EAR = [(0, -40), (34, -52), (62, -58), (84, -96), (104, -62), (128, -70), (146, -112), (166, -68),
       (188, -76), (214, -128), (224, -70), (226, -18), (208, 26), (166, 52), (104, 64), (48, 60), (0, 46)]
MEMBRANE = [(20, -22), (44, -36), (80, -44), (120, -48), (160, -46), (192, -34), (206, -10), (200, 16),
            (178, 36), (140, 48), (92, 50), (50, 42), (24, 22)]
VEIN_FROM = (30, 4)
VEIN_TO = [(198, -38), (204, -10), (196, 18), (170, 36), (126, 46), (84, 46)]


def ears(lift, seed=1):
    """Las dos orejas (atrás de la cabeza). lift: 1 arriba, 0 al medio, -1 abajo."""
    layers = []
    for side in (-1, 1):
        origin = (HC[0] + side * 78, HC[1] - 6)
        ang = -16.0 * lift * side
        ear = _rot(_place(EAR, side, origin), ang, origin)
        mem = _rot(_place(MEMBRANE, side, origin), ang, origin)
        m_ear = _mask([wobble(ear, 2.4, seed + side)])
        m_mem = _mask([wobble(mem, 2.0, seed + 10 + side)])
        layers += [shadow(m_ear, (2, 4), 5, 0.45), paper(m_ear, GREEN_EAR), paper(m_mem, PINK, 0.10)]
        # Nervaduras (líneas finas rojizas en abanico).
        vl = Image.new("RGBA", m_ear.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(vl)
        a = _rot(_place([VEIN_FROM], side, origin), ang, origin)[0]
        for to in VEIN_TO:
            b = _rot(_place([to], side, origin), ang, origin)[0]
            mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2 + 6)
            d.line([(a[0] * HS, a[1] * HS), (mid[0] * HS, mid[1] * HS), (b[0] * HS, b[1] * HS)],
                   fill=VEIN + (150,), width=int(1.6 * HS))
        layers.append(vl)
    return layers


def _superellipse(a, b, n=3.2, steps=90, cx=0.0, cy=0.0, taper=0.0):
    pts = []
    for i in range(steps):
        t = 2 * math.pi * i / steps
        c, s_ = math.cos(t), math.sin(t)
        x = a * math.copysign(abs(c) ** (2 / n), c)
        y = b * math.copysign(abs(s_) ** (2 / n), s_)
        x *= 1.0 + taper * (y / b)
        pts.append((cx + x, cy + y))
    return pts


def _fuzzy_line(d, path, r0, r1, color, seed):
    """Cejas peludas: muchos puntitos a lo largo de un camino."""
    rng = np.random.default_rng(seed)
    pts = _resample(path, 140)
    for x, y in pts:
        for _ in range(3):
            r = rng.uniform(r0, r1)
            jx, jy = rng.normal(0, 2.2, 2)
            d.ellipse([(x + jx - r) * HS, (y + jy - r) * HS, (x + jx + r) * HS, (y + jy + r) * HS], fill=color)


def head(screech=False, seed=3):
    cx, cy = HC
    layers = []
    # Pelos del chichón (detrás de la cabeza).
    wl = Image.new("RGBA", (HW * HS, HH * HS), (0, 0, 0, 0))
    d = ImageDraw.Draw(wl)
    for (x0, y0), (x1, y1), bend in [((-40, -88), (-88, -168), -10), ((-14, -96), (-20, -176), -4),
                                     ((14, -98), (32, -178), 5), ((40, -96), (100, -164), 10)]:
        a, b = (cx + x0, cy + y0), (cx + x1, cy + y1)
        m = ((a[0] + b[0]) / 2 + bend, (a[1] + b[1]) / 2)
        d.line([(a[0] * HS, a[1] * HS), (m[0] * HS, m[1] * HS), (b[0] * HS, b[1] * HS)],
               fill=WHISKER + (235,), width=int(2.2 * HS), joint="curve")
    layers.append(wl)
    # Cabeza: un cuadrado redondeado, un poco más ancho abajo.
    outline = wobble(_superellipse(86, 100, 3.4, cx=cx, cy=cy, taper=0.05), 2.6, seed)
    m_head = _mask([outline])
    layers += [shadow(m_head, (3, 5), 6, 0.5), paper(m_head, GREEN)]
    # Banda más oscura al lado derecho (el pliegue del papel).
    band = _mask([wobble([(cx + 54, cy - 104), (cx + 100, cy - 104), (cx + 100, cy + 104), (cx + 60, cy + 104),
                          (cx + 56, cy + 40)], 1.5, seed + 1)])
    band = Image.fromarray(np.minimum(np.asarray(band), np.asarray(m_head)))
    layers.append(paper(band, GREEN_DARK, 0.06))
    # Arrugas de la frente.
    dl = Image.new("RGBA", m_head.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(dl)
    for y, w in ((-74, 34), (-62, 44)):
        d.arc([(cx - w) * HS, (cy + y - 6) * HS, (cx + w) * HS, (cy + y + 10) * HS], 200, 340,
              fill=(84, 118, 84, 200), width=int(1.4 * HS))
    layers.append(dl)
    # Chichón con brillo.
    m_bump = _mask([wobble(_superellipse(25, 23, 2.0, cx=cx + 42, cy=cy - 92), 1.2, seed + 2)])
    layers += [shadow(m_bump, (2, 3), 3, 0.35), paper(m_bump, PINK, 0.10)]
    m_shine = _mask([wobble(_superellipse(9, 7, 2.0, cx=cx + 42, cy=cy - 98), 0.6, seed + 3)])
    layers.append(paper(m_shine, (205, 208, 205), 0.05, 0.4))
    # Ojos (blancos grandes, pupila gris).
    for side in (-1, 1):
        ex, ey = cx + side * 42, cy - 8
        m_eye = _mask([wobble(_superellipse(23, 22, 2.0, cx=ex, cy=ey), 1.0, seed + 5 + side)])
        layers += [shadow(m_eye, (1, 2), 2, 0.3), paper(m_eye, WHITE, 0.06, 0.4)]
        pr = 8 if screech else 11
        m_p = _mask([wobble(_superellipse(pr, pr, 2.0, cx=ex - side * 3, cy=ey + 1), 0.6, seed + 7 + side)])
        layers.append(paper(m_p, PUPIL if not screech else (160, 70, 60), 0.04, 0.3))
    # Cejas blancas peludas (más bajas al medio si grita: enojado).
    bl = Image.new("RGBA", m_head.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(bl)
    mid = 14 if screech else 0
    brow = [(cx - 74, cy - 30), (cx - 60, cy - 40), (cx - 44, cy - 38), (cx - 26, cy - 46 + mid),
            (cx - 8, cy - 40 + mid), (cx + 6, cy - 54 + mid), (cx + 22, cy - 42 + mid), (cx + 44, cy - 46),
            (cx + 60, cy - 38), (cx + 76, cy - 30)]
    _fuzzy_line(d, brow + brow[::-1][1:-1], 3.0, 6.0, BROW + (255,), seed + 9)
    bl = bl.filter(ImageFilter.GaussianBlur(0.8 * HS))
    layers += [bl]
    # Nariz larga, un poco torcida.
    nose = wobble([(cx - 6, cy - 34), (cx + 10, cy - 36), (cx + 20, cy + 6), (cx + 34, cy + 40), (cx + 26, cy + 56),
                   (cx + 4, cy + 58), (cx - 18, cy + 50), (cx - 20, cy + 30), (cx - 10, cy - 4)], 1.4, seed + 11)
    m_nose = _mask([nose])
    layers += [shadow(m_nose, (3, 4), 4, 0.45), paper(m_nose, NOSE, 0.12)]
    nl = Image.new("RGBA", m_head.size, (0, 0, 0, 0))
    ImageDraw.Draw(nl).line([((cx - 2) * HS, (cy + 46) * HS), ((cx + 14) * HS, (cy + 52) * HS)],
                            fill=(70, 100, 70, 200), width=int(1.6 * HS))
    layers.append(nl)
    # Boca: abierta con cuatro dientes (gritando: más grande y con lengua).
    if screech:
        mouth = [(cx - 54, cy + 62), (cx + 54, cy + 62), (cx + 46, cy + 96), (cx + 20, cy + 122),
                 (cx - 20, cy + 122), (cx - 46, cy + 96)]
    else:
        mouth = [(cx - 50, cy + 70), (cx + 50, cy + 70), (cx + 42, cy + 88), (cx + 16, cy + 104),
                 (cx - 16, cy + 104), (cx - 42, cy + 88)]
    m_mouth = _mask([wobble(mouth, 1.2, seed + 13)])
    layers.append(paper(m_mouth, MOUTH, 0.0, 0.3))
    if screech:
        m_t = _mask([wobble(_superellipse(26, 14, 2.0, cx=cx, cy=cy + 108), 1.0, seed + 15)])
        m_t = Image.fromarray(np.minimum(np.asarray(m_t), np.asarray(m_mouth)))
        layers.append(paper(m_t, TONGUE, 0.06, 0.5))
    top = 62 if screech else 70
    teeth = []
    for k in range(4):
        x = cx - 33 + k * 22
        teeth.append(wobble([(x - 6.5, cy + top + 2), (x + 6.5, cy + top + 2), (x + 6.5, cy + top + 15),
                             (x - 6.5, cy + top + 15)], 0.6, seed + 20 + k, 40))
    layers.append(paper(_mask(teeth), TEETH, 0.05, 0.4))
    return layers


def compose(layers, glow=True):
    base = Image.new("RGBA", (HW * HS, HH * HS), (0, 0, 0, 0))
    for layer in layers:
        base = Image.alpha_composite(base, layer)
    if glow:
        # Brillo verde suave alrededor (es un espíritu de noche).
        a = base.split()[3].filter(ImageFilter.GaussianBlur(9 * HS)).point(lambda v: int(v * 0.35))
        g = Image.new("RGBA", base.size, (150, 220, 160, 0))
        g.putalpha(a)
        base = Image.alpha_composite(g, base)
    return base.resize((HW, HH), Image.LANCZOS)


def cabeza(lift, screech=False):
    return compose(ears(lift) + head(screech))


def trozo():
    """Trocito de papel verde (partículas al pegarle a la cabeza)."""
    global HW, HH, _GRAIN
    keep = HW, HH, _GRAIN
    HW, HH, _GRAIN = 40, 40, None
    pts = wobble([(8, 12), (30, 6), (34, 26), (14, 34)], 1.5, 4, 60)
    m = _mask([pts])
    img = compose([paper(m, GREEN, 0.15)], glow=False)
    HW, HH, _GRAIN = keep
    return img


def vida():
    """Cabecita del Tue Tue (una vida en la barra del HUD)."""
    img = cabeza(0.4).crop((40, 30, 600, 350))
    return img.resize((80, 46), Image.LANCZOS)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(OUT_PAJARO, exist_ok=True)
    # Diseño "cabeza" (el que se usa).
    for i, lift in enumerate((1.0, 0.0, -1.0), start=1):
        cabeza(lift).save(os.path.join(OUT, "vuelo_%d.png" % i))
    cabeza(0.5, screech=True).save(os.path.join(OUT, "grito.png"))
    trozo().save(os.path.join(OUT, "trozo.png"))
    vida().save(os.path.join(OUT, "vida.png"))
    estrella().save(os.path.join(OUT, "estrella.png"))
    # Diseño "pájaro" (alternativo).
    for i, lift in enumerate((1.0, 0.1, -0.9), start=1):
        bird(lift).save(os.path.join(OUT_PAJARO, "vuelo_%d.png" % i))
    bird(0.3, screech=True).save(os.path.join(OUT_PAJARO, "grito.png"))
    pluma().save(os.path.join(OUT_PAJARO, "pluma.png"))
    vida_pajaro().save(os.path.join(OUT_PAJARO, "vida.png"))
    print("arte del Tue Tue en", os.path.normpath(OUT))
