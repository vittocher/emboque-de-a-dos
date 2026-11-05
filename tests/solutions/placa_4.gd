extends RefCounted
const SCENE := "res://scenes/levels/placa_4.tscn"
## Placa 4 "Relevo": la puerta que corta el columpio de cada uno la abre una
## placa del OTRO. J2 se para en la placa de su repisa → se abre la puerta de J1,
## que salta, engancha, se columpia por debajo de la cortina y cae en la isla del
## medio; ahí se para en la placa azul → se abre la puerta de J2, que hace lo
## mismo. Juntan los extremos colgando bajo la isla (cuenco).
const M := preload("res://tests/solutions/moves.gd")

static func plan(ctx) -> Dictionary:
	var pump: float = ctx.var_f("pump", 1.3)
	return {
		"p1": [["wait_floor"], ["walk_to", 110.0, 3], ["tap", "jump"], ["wait_floor"], ["walk_to", 70.0, 3],
			["sync", "abierta1"], ["wait", 1.6]] + M.run_jump(1, 1, 120)
			+ M.swing_launch(1, 1, pump, 420, 560)
			+ [["walk_to", 690.0, 3], ["sync", "en_placa"], ["sync", "llego2"], ["walk_to", 618.0, 3],
			["sync", "centro"]] + M.nudge(1, 618, 60),
		"p2": [["wait_floor"], ["walk_to", 1170.0, 3], ["tap", "jump"], ["wait_floor"],
			["walk_to", ctx.var_f("p2x", 1235), 3], ["sync", "abierta1"], ["sync", "en_placa"],
			["wait", 1.6]] + M.run_jump(2, -1, 1160) + M.swing_launch(2, -1, pump, 860, 720)
			+ [["sync", "llego2"], ["walk_to", 662.0, 3], ["sync", "centro"]] + M.nudge(2, 662, -60),
	}
