"""Montaje del tráiler: corta los clips grabados (record.sh) al ritmo de la cueca,
pone las tarjetas y los textos (cards.py) y mezcla la música con los efectos de
sonido de cada clip.

Uso: python3 trailer/edit.py <carpeta_clips> <carpeta_tarjetas> <salida.mp4>

El guion (qué clip, desde qué segundo, cuántos tiempos dura y qué texto lleva)
está en EDL: para cambiar el tráiler, se cambia ahí. Cada corte cae en un tiempo
de la música (BEAT); la entrada de la banda (DROP) cae justo en el logo.
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MUSIC = os.path.join(ROOT, "audio", "cueca.ogg")
FPS = 30
BEAT = 60.0 / 112.3          # la cueca va a ~112 tiempos por minuto
DROP = 15.95                 # segundo de la canción en que entra la banda completa
DROP_BEAT = 20               # tiempo del tráiler en que cae (= el logo)
MUSIC_START = DROP - DROP_BEAT * BEAT
SFX_GAIN = 3.4               # los efectos del juego, sobre la música
MUSIC_GAIN = 0.72

# kind: "card" (imagen) o "clip" (gameplay). beats: duración en tiempos.
# clip: src (nombre del .avi), start (s), cap (texto de cards_*/cap_*.png),
#       cap_beats (cuántos tiempos se queda el texto; si no, todo el segmento),
#       crop (x, y, w, h) para acercar. card: img, zoom (cuánto crece), flash.
EDL = [
    {"kind": "card", "img": "open.png", "beats": 8, "zoom": 0.05, "fade_in": 0.6},
    {"kind": "clip", "src": "tronco_1", "start": 1.6, "beats": 12, "cap": "cap_dos"},
    {"kind": "card", "img": "logo.png", "beats": 8, "zoom": 0.07, "flash": True},
    {"kind": "clip", "src": "tronco_2", "start": 3.0, "beats": 8, "cap": "cap_cuerda", "crop": (300, 150, 853, 480)},
    {"kind": "clip", "src": "tronco_3", "start": 2.0, "beats": 8, "cap": "cap_balanceo"},
    {"kind": "clip", "src": "lanzar_1", "start": 1.7, "beats": 8, "cap": "cap_lanzar"},
    {"kind": "clip", "src": "peligro_1", "start": 8.6, "beats": 8, "cap": "cap_peligros"},
    {"kind": "clip", "src": "placa_4", "start": 3.5, "beats": 8, "cap": "cap_placas"},
    {"kind": "clip", "src": "movil_3", "start": 6.0, "beats": 8, "cap": "cap_movil"},
    {"kind": "clip", "src": "viento_1", "start": 4.0, "beats": 8, "cap": "cap_viento"},
    {"kind": "clip", "src": "level_4", "start": 12.6, "beats": 12, "cap": "cap_emboque", "cap_beats": 6},
    {"kind": "card", "img": "manifesto_1.png", "beats": 3},
    {"kind": "card", "img": "manifesto_2.png", "beats": 3},
    {"kind": "card", "img": "manifesto_3.png", "beats": 5, "zoom": 0.03},
    {"kind": "clip", "src": "mapa", "start": 0.2, "beats": 8, "cap": "cap_mapa"},
    {"kind": "clip", "src": "caja_2", "start": 9.4, "beats": 2},
    {"kind": "clip", "src": "lanzar_4", "start": 4.0, "beats": 2},
    {"kind": "clip", "src": "viento_4", "start": 3.6, "beats": 2},
    {"kind": "clip", "src": "final", "start": 2.6, "beats": 2},
    {"kind": "card", "img": "end.png", "beats": 12, "zoom": 0.04, "fade_out": 1.2},
]


def run(cmd):
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)


def frame_bounds():
    """Primer cuadro de cada segmento, redondeando la posición en tiempos (sin deriva)."""
    bounds, beats = [], 0
    for seg in EDL:
        bounds.append(round(beats * BEAT * FPS))
        beats += seg["beats"]
    bounds.append(round(beats * BEAT * FPS))
    return bounds


def render_segment(i, seg, frames, clips, cards, out):
    dur = frames / FPS
    enc = ["-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p", "-r", str(FPS),
           "-frames:v", str(frames), "-an", out]
    if seg["kind"] == "card":
        z = seg.get("zoom", 0.0)
        vf = (f"scale=w='trunc(1280*(1+{z}*t/{dur})/2)*2':h=-2:eval=frame,crop=1280:720,setsar=1")
        if seg.get("fade_in"):
            vf += f",fade=t=in:st=0:d={seg['fade_in']}"
        if seg.get("flash"):
            vf += ",fade=t=in:st=0:d=0.45:color=white"
        if seg.get("fade_out"):
            vf += f",fade=t=out:st={dur - seg['fade_out']:.3f}:d={seg['fade_out']}"
        run(["ffmpeg", "-y", "-loop", "1", "-framerate", str(FPS), "-i", os.path.join(cards, seg["img"]),
             "-vf", vf] + enc)
        return
    src = os.path.join(clips, seg["src"] + ".avi")
    chain = "[0:v]"
    if seg.get("crop"):
        x, y, w, h = seg["crop"]
        chain += f"crop={w}:{h}:{x}:{y},scale=1280:720,"
    chain += "setsar=1,fps=30[v]"
    if seg.get("cap"):
        # El texto entra deslizándose desde la izquierda y se va con un fundido.
        cap = os.path.join(cards, seg["cap"] + ".png")
        cap_end = seg["cap_beats"] * BEAT if seg.get("cap_beats") else dur
        fc = (chain + f";[1:v]format=rgba,fade=t=in:st=0.2:d=0.3:alpha=1,"
              f"fade=t=out:st={cap_end - 0.45:.3f}:d=0.3:alpha=1[c];"
              f"[v][c]overlay=x='if(lt(t,0.2),-500,if(lt(t,0.55),-500+(t-0.2)/0.35*500,0))':y=0:eval=frame[o]")
        run(["ffmpeg", "-y", "-ss", str(seg["start"]), "-i", src, "-loop", "1", "-framerate", str(FPS), "-i", cap,
             "-filter_complex", fc, "-map", "[o]"] + enc)
    else:
        run(["ffmpeg", "-y", "-ss", str(seg["start"]), "-i", src, "-filter_complex", chain, "-map", "[v]"] + enc)


def main():
    clips, cards, out = sys.argv[1], sys.argv[2], sys.argv[3]
    bounds = frame_bounds()
    total = bounds[-1] / FPS
    tmp = tempfile.mkdtemp(prefix="trailer_")
    parts = []
    for i, seg in enumerate(EDL):
        frames = bounds[i + 1] - bounds[i]
        path = os.path.join(tmp, f"seg_{i:02d}.mp4")
        render_segment(i, seg, frames, clips, cards, path)
        parts.append(path)
        print(f"segmento {i + 1}/{len(EDL)}: {seg.get('src', seg.get('img'))} ({frames} cuadros)")
    listing = os.path.join(tmp, "list.txt")
    with open(listing, "w") as f:
        f.writelines(f"file '{p}'\n" for p in parts)
    video = os.path.join(tmp, "video.mp4")
    run(["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", listing, "-c", "copy", video])

    # Audio: la cueca entera de fondo (con la entrada de la banda en el logo) y,
    # encima, los efectos del juego de cada clip en su lugar.
    inputs = ["-ss", f"{MUSIC_START:.3f}", "-t", f"{total:.3f}", "-i", MUSIC]
    filters = [f"[0:a]volume={MUSIC_GAIN},afade=t=in:st=0:d=0.8,afade=t=out:st={total - 4.0:.3f}:d=4.0[m]"]
    mix = ["[m]"]
    n = 1
    for i, seg in enumerate(EDL):
        if seg["kind"] != "clip" or seg["src"] == "mapa":
            continue
        dur = (bounds[i + 1] - bounds[i]) / FPS
        inputs += ["-ss", str(seg["start"]), "-t", f"{dur:.3f}", "-i", os.path.join(clips, seg["src"] + ".avi")]
        delay = int(bounds[i] / FPS * 1000)
        filters.append(f"[{n}:a]volume={SFX_GAIN},afade=t=out:st={dur - 0.08:.3f}:d=0.08,"
                       f"adelay={delay}|{delay}[s{n}]")
        mix.append(f"[s{n}]")
        n += 1
    filters.append("".join(mix) + f"amix=inputs={len(mix)}:normalize=0:duration=first,alimiter=limit=0.95[a]")
    audio = os.path.join(tmp, "audio.m4a")
    run(["ffmpeg", "-y"] + inputs + ["-filter_complex", ";".join(filters), "-map", "[a]",
                                     "-c:a", "aac", "-b:a", "192k", audio])
    # Codificación final más liviana (sin diferencia visible) para que pese ~11 MB.
    run(["ffmpeg", "-y", "-i", video, "-i", audio, "-c:v", "libx264", "-preset", "slow", "-crf", "21",
         "-pix_fmt", "yuv420p", "-c:a", "copy", "-shortest", "-movflags", "+faststart", out])
    print(f"listo: {out} ({total:.1f} s)")


if __name__ == "__main__":
    main()
