#!/usr/bin/env bash
# Convierte el video de la intro al formato que lee Godot: video/intro.ogv
# (Ogg Theora + Vorbis, 1280x720 como máximo, 30 fps).
# Uso: tools/convertir_video.sh mi_video.mp4 [calidad 0-10, por defecto 7]
set -euo pipefail
if [[ $# -lt 1 ]]; then
	echo "Uso: $0 mi_video.mp4 [calidad 0-10]" >&2
	exit 1
fi
command -v ffmpeg >/dev/null || { echo "Falta ffmpeg (Windows: winget install Gyan.FFmpeg; Mac: brew install ffmpeg)." >&2; exit 1; }
out="$(cd "$(dirname "$0")/.." && pwd)/video/intro.ogv"
ffmpeg -hide_banner -loglevel warning -stats -y -i "$1" \
	-vf "scale=1280:720:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2,fps=30" \
	-pix_fmt yuv420p -c:v libtheora -q:v "${2:-7}" -c:a libvorbis -q:a 5 -ar 44100 -ac 2 "$out"
echo "Listo: $out ($(du -h "$out" | cut -f1)). Abre el proyecto en Godot y haz commit de intro.ogv + intro.ogv.uid."
