"""Arte PROVISORIO del Tue Tue (jefe final), dibujado por código hasta que llegue
el definitivo: un pájaro nocturno de mal agüero (cuerpo oscuro, ojos amarillos
enormes, penachos y alas de plumas).

Uso (desde la raíz del proyecto):  python3 tools/generate_tuetue_art.py
Requiere Pillow. Escribe en assets/enemigos/tue_tue/:
  vuelo_1..3.png  aleteo (alas arriba, al medio y abajo)
  grito.png       chillando (pico abierto, ojos rojos): aviso de un ataque
  pluma.png       pluma suelta (partículas al pegarle)
  estrella.png    estrellita (mareado tras un golpe en la cima)
  vida.png        pluma dorada: una vida en la barra del HUD
Para el arte definitivo basta con reemplazar estos archivos (mismo nombre); el
pájaro se dibuja mirando de frente.
"""

import math
import os

from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "enemigos", "tue_tue")
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


def vida():
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


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for i, lift in enumerate((1.0, 0.1, -0.9), start=1):
        bird(lift).save(os.path.join(OUT, "vuelo_%d.png" % i))
    bird(0.3, screech=True).save(os.path.join(OUT, "grito.png"))
    pluma().save(os.path.join(OUT, "pluma.png"))
    estrella().save(os.path.join(OUT, "estrella.png"))
    vida().save(os.path.join(OUT, "vida.png"))
    print("arte del Tue Tue en", os.path.normpath(OUT))
