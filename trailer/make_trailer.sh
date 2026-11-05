#!/usr/bin/env bash
# Rehace el tráiler de punta a punta: graba el gameplay con el bot (Movie Maker
# de Godot), genera las tarjetas y monta el video con la cueca.
#
# Uso:  GODOT=/ruta/a/godot trailer/make_trailer.sh [es|en]   (por defecto es)
# Necesita: Godot 4.7 (con pantalla; en Linux sin pantalla, xvfb-run), ffmpeg,
# Python 3 con Pillow. Las fuentes (Bungee y Barlow Semi Condensed, licencia OFL)
# se bajan solas de Google Fonts la primera vez.
# Tarda unos 10 minutos (cada nivel se graba en tiempo real).
set -euo pipefail
cd "$(dirname "$0")/.."
LANG_CODE="${1:-es}"
GODOT="${GODOT:-godot}"
WORK="${WORK:-build/trailer}"
CLIPS="$WORK/clips_$LANG_CODE"
FONTS="$WORK/fonts"
mkdir -p "$CLIPS" "$FONTS"

# Pantalla: en Linux sin X se usa xvfb-run.
RUN=("$GODOT")
if [[ "$(uname)" == "Linux" && -z "${DISPLAY:-}" ]] && command -v xvfb-run >/dev/null; then
	RUN=(xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --rendering-driver opengl3)
fi

# Fuentes de las tarjetas.
for f in bungee/Bungee-Regular.ttf barlowsemicondensed/BarlowSemiCondensed-SemiBold.ttf; do
	[[ -f "$FONTS/$(basename "$f")" ]] || curl -sSfL -o "$FONTS/$(basename "$f")" \
		"https://raw.githubusercontent.com/google/fonts/main/ofl/$f"
done

# Calidad del MJPEG de Movie Maker (override.cfg temporal: se borra al terminar).
printf '[editor]\n\nmovie_writer/mjpeg_quality=0.95\n' > override.cfg
trap 'rm -f override.cfg' EXIT

# Los niveles que usa el guion de edit.py (EDL).
LEVELS=(tronco_1 tronco_2 tronco_3 lanzar_1 lanzar_4 peligro_1 caja_2 placa_4 movil_3 viento_1 viento_4 level_4 final)
for n in "${LEVELS[@]}"; do
	"${RUN[@]}" --path . --write-movie "$CLIPS/$n.avi" --fixed-fps 30 -s tests/play_level.gd -- \
		"res://tests/solutions/$n.gd" --linger=3.5 --lang="$LANG_CODE" --music=0 --timeout=60 \
		> "$CLIPS/$n.log" 2>&1 || true
	echo "$n: $(grep -m1 RESULT "$CLIPS/$n.log" || echo 'sin resultado')"
done
"${RUN[@]}" --path . --write-movie "$CLIPS/mapa.avi" --fixed-fps 30 -s tests/rec_map.gd -- "$LANG_CODE" \
	> "$CLIPS/mapa.log" 2>&1
echo "mapa: grabado"

python3 trailer/cards.py "$LANG_CODE" "$FONTS" "$WORK/cards_$LANG_CODE"
python3 trailer/edit.py "$CLIPS" "$WORK/cards_$LANG_CODE" "trailer/trailer_$LANG_CODE.mp4"
