#!/usr/bin/env bash
# Rehace la portada del menú (assets/ui/portada.png y assets/ui/en/portada.png) con el
# ambiente de los niveles: Godot dibuja la pared, las plataformas de madera (TerrainArt),
# las sopaipillas y la placa de madera de los controles (render_fondo.gd), y encima va lo
# de adelante de la portada ORIGINAL del equipo (título, personajes, cuerda, emboque y
# controles), que extraer.py separa de su fondo plano y componer.py pega con sombra.
#
# Uso (desde la raíz del proyecto):  GODOT=/ruta/a/godot tools/portada/hacer_portada.sh
# Necesita Python con Pillow y numpy. En Linux sin pantalla corre Godot con xvfb-run.
# Las originales están en assets/ui/alternativos/ (portada_original.png y en/...):
# si cambian (otros controles, otro dibujo), reemplazarlas ahí y volver a correr esto.
set -e
cd "$(dirname "$0")/../.."
GODOT="${GODOT:-godot}"
TMP=$(mktemp -d)
RUN=()
if [[ -z "$DISPLAY" && -x "$(command -v xvfb-run)" ]]; then
	RUN=(xvfb-run -a -s "-screen 0 1920x1080x24")
fi
"${RUN[@]}" "$GODOT" --path . --resolution 1920x1080 --rendering-driver opengl3 --audio-driver Dummy -s tools/portada/render_fondo.gd -- "$TMP"
for lang in es en; do
	if [[ $lang == es ]]; then src=assets/ui/alternativos/portada_original.png; dst=assets/ui/portada.png
	else src=assets/ui/alternativos/en/portada_original.png; dst=assets/ui/en/portada.png; fi
	python3 tools/portada/extraer.py "$src" "$TMP/adelante_$lang.png"
	python3 tools/portada/componer.py "$TMP/fondo.png" "$TMP/adelante_$lang.png" "$dst" wood
	echo "listo: $dst"
done
rm -rf "$TMP"
