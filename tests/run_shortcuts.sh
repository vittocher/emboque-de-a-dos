#!/usr/bin/env bash
# Atajos: el "mono tramposo" (tests/monkey.gd) juega al azar SIN la mecánica clave del nivel
# y no debe ganar (ni llegar a la meta parcial de --goal). Cada solución puede declarar
#   const SHORTCUTS := ["--no=rope", "--no=hook --goal=470,448,1130,568"]
# (cada texto son opciones de monkey.gd).
# Uso: GODOT=/ruta/a/godot tests/run_shortcuts.sh [filtro] [segundos de juego, default 1500]
# Sale con código 1 si el mono encuentra un atajo. Que no lo encuentre no prueba que no exista.
cd "$(dirname "$0")/.." || exit 2
GODOT="${GODOT:-godot}"
secs="${2:-1500}"
fail=0
for f in tests/solutions/*.gd; do
	name=$(basename "$f" .gd)
	[[ -n "$1" && "$name" != *"$1"* ]] && continue
	scene=$(grep -oE 'res://scenes/[^"]+\.tscn' "$f" | head -1)
	while read -r opts; do
		[[ -z "$opts" ]] && continue
		out=$(timeout 600 "$GODOT" --headless --fixed-fps 120 --path . -s tests/monkey.gd -- "$scene" $opts --time="$secs" 2>&1 < /dev/null)
		result=$(echo "$out" | grep -E "^MONKEY" | head -1)
		ok="OK"
		[[ "$result" != "MONKEY NO"* ]] && ok="ATAJO" && fail=1
		printf "%-12s %-70s %-6s %s
" "$name" "$opts" "$ok" "${result:-MONKEY ERROR}"
	done < <(grep -E '^const SHORTCUTS' "$f" | grep -oE '"[^"]+"' | tr -d '"')
done
exit $fail
