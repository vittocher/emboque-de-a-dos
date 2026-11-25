extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--no=rope --goal=680,438,920,438", "--start=690,370,910,370 --goal=910,438,690,438"]
const SCENE := "res://scenes/levels/peligro_3.tscn"
## Peligro 3 "Brasas": cada peligro se pasa distinto. J1 sube islas sobre el fuego (mata a los dos: cuerda corta).
## J2: brasa (cuerda corta) → púas con caca colgando encima: él salta A TRAVÉS de la caca y el extremo
## tiene que pasar por abajo, arrastrando por las púas (cuerda larga) → puente tapado de caca: el extremo va por
## DEBAJO (se baja por la ranura y se alarga la cuerda). En la meta, los extremos cuelgan justo sobre
## el fuego: muy largos se queman; hay que balancearse los dos a la vez (S = 100).
const M := preload("res://tests/solutions/moves.gd")

static func plan(ctx) -> Dictionary:
	var m: float = ctx.var_f("m", 45)
	var r: float = ctx.var_f("r", 140)
	return {
		"p1": [["wait_floor"], ["rope", 60]] + M.path(1, [[89, 264], [298, 385], [398, 285], [253, 145], [140, 274]]) + [["rope", ctx.var_f("long1", 190)], ["wait", 0.5]] + [["hold_jump", ctx.var_f("h", 0.5)]] + M.path(1, [[293, 530]]) + [["hold_jump", 0.5], ["rope", 60], ["wait", 0.4]] + M.path(1, [["go", 690]])
			+ [["hang", 743], ["rope", r], ["wait", 0.6], ["sync", "listos"], ["swing", 743, m, 24]],
		"p2": [["wait_floor"], ["rope", 60]] + M.path(2, [["over", 1492, 1462]]) + [["walk_to", 1375, 4], ["rope", ctx.var_f("long", 240)], ["wait", 0.4]] + [["hold_jump", ctx.var_f("h", 0.5)]] + M.path(2, [[1380, 1205], ["go", 1150]]) + [["hold_jump", 0.5]]
			+ [["rope", 60], ["wait", 0.5], ["walk_to", 1150, 4], ["wait_floor"], ["rope", 60], ["wait", 0.5], ["walk_to", 1235, 3], ["wait", 0.6], ["rope", ctx.var_f("under", 125)], ["wait", 0.8], ["walk_to", 1545, 4], ["wait_floor"], ["rope", 60], ["wait", 0.5]]
			+ M.path(2, [["go", 1260], ["over", 1180, 1140], ["over", 1025, 965]])
			+ [["hang", 857], ["rope", r], ["wait", 0.6], ["sync", "listos"], ["swing", 857, -m, 24]],
	}
