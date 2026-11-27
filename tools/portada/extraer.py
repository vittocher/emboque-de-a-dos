"""Separa lo de adelante de la portada (título, personajes, cuerda, emboque, controles)
de su fondo plano (azul marino, círculos y plataformas oscuras)."""
import sys
import numpy as np
from PIL import Image, ImageDraw

PALETTE = np.array([
    (20, 23, 43), (18, 21, 39), (19, 22, 41),     # azul marino (y sus sombras)
    (11, 13, 28), (10, 12, 26),                   # plataformas oscuras
    (47, 85, 201), (216, 64, 47), (38, 40, 57),   # círculos azul, rojo y gris
    (53, 58, 102),                                # borde de las plataformas
], dtype=float)
REGIONS = {5: (0, 0, 620, 620), 6: (1480, 520, 1920, 1080), 7: (1640, 0, 1920, 260)}
PURE = 9.0        # distancia (RGB) para ser fondo puro
BAND = 2          # px de borde en que se quita el fondo mezclado
CHAR_BOXES = [(100, 310, 480, 712), (1440, 310, 1820, 712)]  # personajes: sin agujeros adentro


def extract(src, out):
    img = np.asarray(Image.open(src).convert("RGB"), dtype=float)
    h, w, _ = img.shape
    d = np.linalg.norm(img[:, :, None, :] - PALETTE[None, None, :, :], axis=3)
    # Los círculos de color solo cuentan en su zona (el chaleco rojo de J1 no es el
    # círculo rojo de abajo a la derecha).
    yy, xx = np.mgrid[0:h, 0:w]
    for k, (x0, y0, x1, y1) in REGIONS.items():
        outside = ~((xx >= x0) & (xx < x1) & (yy >= y0) & (yy < y1))
        d[:, :, k][outside] = 1e9
    nearest = d.argmin(axis=2)
    pure = d.min(axis=2) < PURE
    # Sombras de los personajes sobre los círculos: el mismo color, más oscuro.
    for k, (x0, y0, x1, y1) in REGIONS.items():
        c = PALETTE[k]
        kk = (img @ c) / (c @ c)
        resid = np.linalg.norm(img - kk[:, :, None] * c, axis=2)
        inside = (xx >= x0) & (xx < x1) & (yy >= y0) & (yy < y1)
        shadow = inside & (kk > 0.5) & (kk < 1.05) & (resid < 9)
        pure |= shadow
        nearest[shadow] = k
    # Bordes entre dos colores de fondo (ej. círculo sobre el azul marino): están en el
    # segmento entre los dos y pegados a los dos.
    near = {}
    for k in range(len(PALETTE)):
        m = Image.fromarray(((pure & (nearest == k)) * 255).astype(np.uint8))
        near[k] = np.asarray(m.filter(__import__("PIL.ImageFilter", fromlist=["x"]).MaxFilter(7))) > 0
    blend = np.zeros((h, w), bool)
    for i in range(len(PALETTE)):
        for j in range(i + 1, len(PALETTE)):
            a, b = PALETTE[i], PALETTE[j]
            ab = b - a
            if np.linalg.norm(ab) < 20:
                continue
            t = np.clip(((img - a) @ ab) / (ab @ ab), 0, 1)
            proj = a + t[:, :, None] * ab
            dist = np.linalg.norm(img - proj, axis=2)
            blend |= (dist < 6) & near[i] & near[j] & ~pure
    bg = pure | blend
    # Personajes: lo que parece fondo pero está encerrado dentro de ellos es de ellos.
    mask = Image.fromarray((bg * 255).astype(np.uint8))
    for (x0, y0, x1, y1) in CHAR_BOXES:
        sub = mask.crop((x0, y0, x1, y1))
        # Se rellena desde el borde de la caja: lo conectado al exterior queda en 128.
        for sx in range(0, x1 - x0, 6):
            for sy in (0, y1 - y0 - 1):
                if sub.getpixel((sx, sy)) == 255:
                    ImageDraw.floodfill(sub, (sx, sy), 128)
        for sy in range(0, y1 - y0, 6):
            for sx in (0, x1 - x0 - 1):
                if sub.getpixel((sx, sy)) == 255:
                    ImageDraw.floodfill(sub, (sx, sy), 128)
        arr = np.asarray(sub).copy()
        arr[arr == 255] = 0      # agujeros encerrados → figura
        arr[arr == 128] = 255
        mask.paste(Image.fromarray(arr), (x0, y0))
    bg = np.asarray(mask) > 0
    # Color de fondo de cada pixel (el del fondo puro más cercano, hasta BAND px).
    bgcol = np.where(bg[:, :, None], PALETTE[nearest], np.nan)
    known = bg.copy()
    for _ in range(BAND):
        new = bgcol.copy()
        nk = known.copy()
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)):
            sh = np.roll(np.roll(bgcol, dy, 0), dx, 1)
            shk = np.roll(np.roll(known, dy, 0), dx, 1)
            take = ~nk & shk
            new[take] = sh[take]
            nk |= take
        bgcol, known = new, nk
    band = known & ~bg
    alpha = np.where(bg, 0.0, 1.0)
    # Borde: "color a alfa" contra el fondo de al lado (deja el antialias limpio).
    P = img[band]
    B = bgcol[band]
    up = np.where(P > B, (P - B) / np.maximum(255 - B, 1), 0)
    dn = np.where(P < B, (B - P) / np.maximum(B, 1), 0)
    a = np.clip(np.maximum(up, dn).max(axis=1), 0, 1)
    a = np.maximum(a, 0.35)      # lo oscuro sobre oscuro no desaparece del todo
    F = np.clip((P - B) / a[:, None] + B, 0, 255)
    out_rgb = img.copy()
    out_rgb[band] = F
    alpha[band] = a
    # El borde de las plataformas (una línea azul bajo los pies) se va entero.
    rows = slice(688, 708)
    sub = img[rows]
    dl = np.minimum(np.linalg.norm(sub - (53, 58, 102), axis=2), np.linalg.norm(sub - (14, 16, 32), axis=2) * 1.4)
    a_rows = alpha[rows]
    a_rows[dl < 45] = 0
    alpha[rows] = a_rows
    rgba = np.dstack([out_rgb, alpha * 255]).astype(np.uint8)
    Image.fromarray(rgba, "RGBA").save(out)


if __name__ == "__main__":
    extract(sys.argv[1], sys.argv[2])
