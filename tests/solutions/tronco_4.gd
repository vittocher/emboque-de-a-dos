extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--no=hook --goal=522,438,758,298"]
const SCENE := "res://scenes/levels/tronco_4.tscn"
## Tronco 4 "La ventana": cada uno cruza con su gancho por debajo de su cortina (J2 más
## arriba). Entre la repisa y el muro hay una ranura por la que cabe el extremo. El muro tiene
## una ventana: cada uno halla el largo que lo deja frente a ella (J1 corto, J2 largo) y se
## balancean los dos a la vez para juntarse adentro.
const M := preload("res://tests/solutions/moves.gd")

static func plan(ctx) -> Dictionary:
	var pump: float = ctx.var_f("pump", 1.3)
	var m: float = ctx.var_f("m", 40)
	return {
		"p1": [["wait_floor"]] + M.run_jump(1, 1, 120) + M.swing_launch(1, 1, pump, 420, 525)
			+ [["hang", 588], ["rope", ctx.var_f("r1", 160)], ["wait", 1.0], ["sync", "listos"], ["swing", 588, m, 24]],
		"p2": [["wait_floor"]] + M.run_jump(2, -1, 1160) + M.swing_launch(2, -1, pump, 860, 755)
			+ [["hang", 692], ["rope", ctx.var_f("r2", 300)], ["wait", 1.0], ["sync", "listos"], ["swing", 692, -m, 24]],
	}
