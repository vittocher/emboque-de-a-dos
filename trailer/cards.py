"""Tarjetas y textos del tráiler, con el estilo de la portada (fondo azul noche,
círculos de color, Bungee amarilla + Barlow crema y el arte real del juego).

Uso: python3 trailer/cards.py <es|en> <carpeta_fuentes> <carpeta_salida>
Genera PNG de 1280x720: tarjetas opacas (open, logo, end) y textos con fondo
transparente (cap_*) que el montaje (make_trailer.sh) pone sobre el gameplay.
Los textos de cada idioma están en TEXTS: para cambiar una frase, cambiarla ahí.
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 1280, 720
NAVY = (11, 13, 28, 255)
CREAM = (246, 239, 224, 255)
YELLOW = (255, 212, 71, 255)

TEXTS = {
    "es": {
        "open": "Un juguete chileno de toda la vida...",
        "cap_dos": ("AHORA, DE A DOS", "Cada uno lleva una mitad del emboque: la campana o el palito"),
        "tagline": "PUZZLE COOPERATIVO PARA 2 JUGADORES",
        "cap_cuerda": ("LA CUERDA LO ES TODO", "Alárgala y acórtala: física de cuerda de verdad"),
        "cap_balanceo": ("BALANCÉATE", "Engánchate y vuela como en un columpio"),
        "cap_lanzar": ("LANZA EL EMBOQUE", "Apunta, engánchate y trepa por tu propia cuerda"),
        "cap_peligros": ("CUIDADO ABAJO", "Púas para ti, caca para tu emboque y fuego para los dos"),
        "cap_placas": ("UNO ABRE, EL OTRO PASA", "Cajas, placas y compuertas: nadie gana solo"),
        "cap_movil": ("TODO SE MUEVE", "Ascensores y plataformas que hay que coordinar"),
        "cap_viento": ("COMO UN VOLANTÍN", "El viento sube tu emboque hasta donde no llegas"),
        "cap_emboque": ("¡EMBOQUE!", "El palito entra en la campana... en cámara lenta"),
        "cap_mapa": ("28 NIVELES", "Un mapa de caminos que se abren mecánica a mecánica"),
        "manifesto": ("Un juguete tradicional chileno", "convertido en un puzzle de física", "QUE SOLO SE RESUELVE DE A DOS"),
        "end1": "Cooperativo local · 2 jugadores · 1 teclado",
        "end2": "Español · English",
        "end3": "PRÓXIMAMENTE",
    },
    "en": {
        "open": "A classic Chilean toy...",
        "cap_dos": ("NOW FOR TWO", "Each player holds one half of the toy: the cup or the stick"),
        "tagline": "A CO-OP PUZZLE GAME FOR 2 PLAYERS",
        "cap_cuerda": ("THE ROPE IS EVERYTHING", "Let it out, reel it in: real rope physics"),
        "cap_balanceo": ("SWING", "Hook on and fly like a pendulum"),
        "cap_lanzar": ("THROW IT", "Aim, hook on and climb up your own rope"),
        "cap_peligros": ("WATCH YOUR STEP", "Spikes for you, poop for your toy, fire for both"),
        "cap_placas": ("ONE OPENS, ONE GOES", "Boxes, plates and gates: nobody wins alone"),
        "cap_movil": ("EVERYTHING MOVES", "Elevators and platforms you must time together"),
        "cap_viento": ("LIKE A KITE", "The wind lifts your toy where you can't reach"),
        "cap_emboque": ("EMBOQUE!", "The stick lands in the cup... in slow motion"),
        "cap_mapa": ("28 LEVELS", "A branching map that opens up one mechanic at a time"),
        "manifesto": ("A traditional Chilean toy", "turned into a physics puzzle", "THAT ONLY TWO CAN SOLVE"),
        "end1": "Local co-op · 2 players · 1 keyboard",
        "end2": "Español · English",
        "end3": "COMING SOON",
    },
}


def font(fonts, name, size):
    return ImageFont.truetype(os.path.join(fonts, name), size)


def background():
    """Fondo de la portada: azul noche con los tres círculos (como el mapa)."""
    im = Image.new("RGBA", (W, H), NAVY)
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for (cx, cy, r, col) in [(90, 40, 330, (41, 74, 181, 150)), (1260, 760, 260, (204, 64, 41, 120)),
                             (1240, 10, 150, (77, 79, 97, 90))]:
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=col)
    return Image.alpha_composite(im, layer)


def spaced(draw, xy, text, fnt, fill, spacing, anchor_center=True):
    """Texto con letras separadas (como 'CONTROLES' en la portada)."""
    widths = [fnt.getlength(c) for c in text]
    total = sum(widths) + spacing * (len(text) - 1)
    x, y = xy
    if anchor_center:
        x -= total / 2
    for c, w in zip(text, widths):
        draw.text((x, y), c, font=fnt, fill=fill, anchor="ls")
        x += w + spacing


def emboque_art():
    camp = Image.open(os.path.join(ROOT, "assets/emboque/campana.png")).convert("RGBA")
    pal = Image.open(os.path.join(ROOT, "assets/emboque/palito.png")).convert("RGBA")
    return camp, pal


def title_letters():
    """Las letras del título recortadas de la portada (fondo transparente)."""
    src = Image.open(os.path.join(ROOT, "assets/ui/portada.png")).convert("RGBA").crop((380, 20, 1540, 360))
    px = src.load()
    out = Image.new("RGBA", src.size, (0, 0, 0, 0))
    po = out.load()
    for y in range(src.size[1]):
        for x in range(src.size[0]):
            r, g, b, a = px[x, y]
            lum = (0.3 * r + 0.59 * g + 0.11 * b) / 255
            alpha = max(0.0, min(1.0, (lum - 0.42) / 0.18))
            if alpha > 0:
                po[x, y] = (r, g, b, int(255 * alpha))
    return out


def card_open(t, fonts):
    im = background()
    d = ImageDraw.Draw(im)
    d.text((W / 2, 250), t["open"], font=font(fonts, "BarlowSemiCondensed-SemiBold.ttf", 58), fill=CREAM, anchor="mm")
    camp, pal = emboque_art()
    camp = camp.resize((int(camp.width * 0.42), int(camp.height * 0.42)), Image.LANCZOS).rotate(-12, expand=True)
    pal = pal.resize((int(pal.width * 0.5), int(pal.height * 0.5)), Image.LANCZOS).rotate(18, expand=True)
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((W / 2 - 260, 330, W / 2 + 260, 640), fill=(255, 212, 71, 40))
    im = Image.alpha_composite(im, glow.filter(ImageFilter.GaussianBlur(40)))
    im.alpha_composite(pal, (int(W / 2 - 40 - pal.width), 520 - pal.height // 2))
    im.alpha_composite(camp, (int(W / 2 + 70), 500 - camp.height // 2))
    return im


def card_logo(t, fonts, lang):
    """La portada (la del idioma), con la franja de controles tapada y el lema abajo."""
    path = os.path.join(ROOT, "assets/ui", "en" if lang == "en" else "", "portada.png")
    im = Image.open(path).convert("RGBA").resize((W, H), Image.LANCZOS)
    fade = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fade)
    for y in range(500, H):
        a = int(255 * min(1.0, (y - 500) / 50))
        fd.line([(0, y), (W, y)], fill=(11, 13, 28, a))
    im = Image.alpha_composite(im, fade)
    d = ImageDraw.Draw(im)
    spaced(d, (W / 2, 640), t["tagline"], font(fonts, "Bungee-Regular.ttf", 30), YELLOW, 5)
    return im


def caption(heading, sub, fonts):
    """Texto abajo a la izquierda: franja oscura con un borde amarillo."""
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fh = font(fonts, "Bungee-Regular.ttf", 44)
    fs = font(fonts, "BarlowSemiCondensed-SemiBold.ttf", 31)
    w = int(max(fh.getlength(heading), fs.getlength(sub))) + 70
    x0, y0, y1 = 36, 556, 686
    band = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bd = ImageDraw.Draw(band)
    bd.rounded_rectangle((x0 + 4, y0 + 6, x0 + w + 4, y1 + 6), 14, fill=(0, 0, 0, 110))
    band = band.filter(ImageFilter.GaussianBlur(6))
    im = Image.alpha_composite(im, band)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((x0, y0, x0 + w, y1), 14, fill=(11, 13, 28, 225))
    d.rounded_rectangle((x0, y0, x0 + 9, y1), 4, fill=YELLOW)
    d.text((x0 + 34, y0 + 62), heading, font=fh, fill=YELLOW, anchor="ls")
    d.text((x0 + 34, y0 + 106), sub, font=fs, fill=CREAM, anchor="ls")
    return im


def card_manifesto(t, fonts, lines):
    """Las tres frases que resumen la idea; se generan acumulándose (1, 1+2, 1+2+3)."""
    im = background()
    d = ImageDraw.Draw(im)
    l1, l2, l3 = t["manifesto"]
    body = font(fonts, "BarlowSemiCondensed-SemiBold.ttf", 60)
    if lines >= 1:
        d.text((W / 2, 250), l1, font=body, fill=CREAM, anchor="mm")
    if lines >= 2:
        d.text((W / 2, 330), l2, font=body, fill=CREAM, anchor="mm")
    if lines >= 3:
        spaced(d, (W / 2, 450), l3, font(fonts, "Bungee-Regular.ttf", 46), YELLOW, 4)
    return im


def card_end(t, fonts):
    im = background()
    letters = title_letters()
    letters = letters.resize((int(letters.width * 0.78), int(letters.height * 0.78)), Image.LANCZOS)
    im.alpha_composite(letters, ((W - letters.width) // 2, 70))
    d = ImageDraw.Draw(im)
    d.text((W / 2, 440), t["end1"], font=font(fonts, "BarlowSemiCondensed-SemiBold.ttf", 40), fill=CREAM, anchor="mm")
    d.text((W / 2, 492), t["end2"], font=font(fonts, "BarlowSemiCondensed-SemiBold.ttf", 30), fill=(200, 196, 186, 255), anchor="mm")
    spaced(d, (W / 2, 600), t["end3"], font(fonts, "Bungee-Regular.ttf", 50), YELLOW, 10)
    camp, pal = emboque_art()
    camp = camp.resize((int(camp.width * 0.22), int(camp.height * 0.22)), Image.LANCZOS)
    pal = pal.resize((int(pal.width * 0.26), int(pal.height * 0.26)), Image.LANCZOS).rotate(30, expand=True)
    im.alpha_composite(pal, (150, 470))
    im.alpha_composite(camp, (W - 150 - camp.width, 480))
    return im


def main():
    lang, fonts, out = sys.argv[1], sys.argv[2], sys.argv[3]
    os.makedirs(out, exist_ok=True)
    t = TEXTS[lang]
    card_open(t, fonts).save(os.path.join(out, "open.png"))
    card_logo(t, fonts, lang).save(os.path.join(out, "logo.png"))
    card_end(t, fonts).save(os.path.join(out, "end.png"))
    for n in (1, 2, 3):
        card_manifesto(t, fonts, n).save(os.path.join(out, f"manifesto_{n}.png"))
    for key, value in t.items():
        if key.startswith("cap_"):
            caption(value[0], value[1], fonts).save(os.path.join(out, key + ".png"))
    print("tarjetas listas en", out)


if __name__ == "__main__":
    main()
