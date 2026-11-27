"""Portada nueva: ambiente de los niveles (render de Godot) + lo de adelante de la portada
original (título, personajes, cuerda, emboque y controles), con sombras como en el juego."""
import sys
import numpy as np
from PIL import Image, ImageFilter, ImageDraw

CONTROLS_Y = 826       # de acá para abajo están los controles (van sobre la placa, sin sombra)


def shadow(layer, offset=(7, 10), blur=7, strength=0.5):
    a = layer.split()[3]
    sh = Image.new("L", layer.size, 0)
    sh.paste(a, offset)
    sh = sh.filter(ImageFilter.GaussianBlur(blur)).point(lambda v: int(v * strength))
    out = Image.new("RGBA", layer.size, (8, 10, 20, 0))
    out.putalpha(sh)
    return out


def compose(bg_path, fg_path, out_path, panel="wood"):
    bg = Image.open(bg_path).convert("RGBA")
    fg = Image.open(fg_path).convert("RGBA")
    w, h = fg.size
    top = fg.copy()
    ImageDraw.Draw(top).rectangle([0, CONTROLS_Y, w, h], fill=(0, 0, 0, 0))
    bottom = fg.copy()
    ImageDraw.Draw(bottom).rectangle([0, 0, w, CONTROLS_Y - 1], fill=(0, 0, 0, 0))
    img = bg.copy()
    if panel == "dark":
        p = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(p)
        d.rounded_rectangle([162, 826, 1758, 1062], 22, fill=(12, 14, 28, 222), outline=(250, 209, 77, 255), width=4)
        img.alpha_composite(shadow(p, (6, 9), 9, 0.55))
        img.alpha_composite(p)
    img.alpha_composite(shadow(top))
    img.alpha_composite(top)
    img.alpha_composite(bottom)
    img.convert("RGB").save(out_path, optimize=True)


if __name__ == "__main__":
    compose(*sys.argv[1:5])
