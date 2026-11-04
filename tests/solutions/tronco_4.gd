extends RefCounted
## Tronco 4: cada uno cruza con su gancho por debajo de su cortina (J2 más
## arriba). Ya junto al muro, bajan los extremos dentro del cuenco: J1 un poco,
## J2 casi todo el largo; se deslizan al fondo y se emboca.
const M := preload("res://tests/solutions/moves.gd")

static func plan(ctx) -> Dictionary:
	var pump: float = ctx.var_f("pump", 1.3)
	return {
		"p1": [["wait_floor"]] + M.run_jump(1, 1, 120) + M.swing_launch(1, 1, pump, 420, 560)
			+ [["rope", 110], ["walk_to", 612], ["wait", 1.0], ["rope", ctx.var_f("r1", 190)],
			["sync", "listos"]] + M.nudge(1, 612, 30, 10),
		"p2": [["wait_floor"]] + M.run_jump(2, -1, 1160) + M.swing_launch(2, -1, pump, 860, 720)
			+ [["walk_to", 668], ["wait", 1.0], ["rope", ctx.var_f("r2", 320)],
			["sync", "listos"]] + M.nudge(2, 668, -30, 10),
	}
