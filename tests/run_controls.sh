#!/usr/bin/env bash
# Controles: niveles que NO se deben ganar si alguien no se balancea en la meta.
# Cada solución puede declarar `const CONTROLS := ["12", "1", "2"]`: con esos jugadores
# quietos (--still: llegan a la meta pero se saltan swing / jiggle) el bot no debe ganar.
# "12" = los dos quietos, "1" / "2" = solo ese quieto.
# Uso: GODOT=/ruta/a/godot tests/run_controls.sh [filtro]
# Sale con código 1 si algún control se gana.
cd "$(dirname "$0")/.." || exit 2
GODOT="${GODOT:-godot}"
fail=0
for f in tests/solutions/*.gd; do
	name=$(basename "$f" .gd)
	[[ -n "$1" && "$name" != *"$1"* ]] && continue
	for who in $(grep -E '^const CONTROLS' "$f" | grep -oE '"[12]+"' | tr -d '"'); do
		out=$(timeout 240 "$GODOT" --headless --fixed-fps 120 --path . -s tests/play_level.gd -- "res://$f" --timeout=90 --still="$who" 2>&1)
		result=$(echo "$out" | grep -E "^RESULT" | head -1)
		ok="OK"
		[[ -z "$result" || "$result" == "RESULT WIN"* || "$result" == "RESULT ERROR"* ]] && ok="FALLA" && fail=1
		printf "%-14s quieto=%-3s %-6s %s\n" "$name" "$who" "$ok" "${result:-RESULT ERROR}"
	done
done
exit $fail
