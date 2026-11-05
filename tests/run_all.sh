#!/usr/bin/env bash
# Corre el bot en todas las soluciones de tests/solutions y resume el resultado.
# Uso: GODOT=/ruta/a/godot tests/run_all.sh [filtro]
# Sale con código 1 si algún nivel no se gana.
cd "$(dirname "$0")/.." || exit 2
GODOT="${GODOT:-godot}"
fail=0
for f in tests/solutions/*.gd; do
	name=$(basename "$f" .gd)
	[[ "$name" == moves || "$name" == _* ]] && continue
	[[ -n "$1" && "$name" != *"$1"* ]] && continue
	out=$(timeout 120 "$GODOT" --headless --fixed-fps 120 --path . -s tests/play_level.gd -- "res://$f" --timeout=60 2>&1)
	result=$(echo "$out" | grep -E "^RESULT" | head -1)
	missing=$(echo "$out" | grep -E "^MISSING" | head -1)
	printf "%-14s %s %s\n" "$name" "${result:-RESULT ERROR}" "$missing"
	[[ "$result" == "RESULT WIN"* ]] || fail=1
done
exit $fail
