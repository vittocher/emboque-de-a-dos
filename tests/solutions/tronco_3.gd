extends RefCounted
const SCENE := "res://scenes/levels/tronco_3.tscn"
## Tronco 3: cada uno corre, salta, su extremo se engancha en el gancho, bombea
## y se lanza por debajo de la cortina a la plataforma central; ahí juntan los
## extremos colgando bajo la plataforma.
const M := preload("res://tests/solutions/moves.gd")

static func plan(ctx) -> Dictionary:
	var pump: float = ctx.var_f("pump", 1.3)
	return {
		"p1": [["wait_floor"]] + M.run_jump(1, 1, 120) + M.swing_launch(1, 1, pump, 420, 560)
			+ [["walk_to", 618], ["sync", "centro"]] + M.nudge(1, 618, 60),
		"p2": [["wait_floor"]] + M.run_jump(2, -1, 1160) + M.swing_launch(2, -1, pump, 860, 720)
			+ [["walk_to", 662], ["sync", "centro"]] + M.nudge(2, 662, -60),
	}
