extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--no=hook --goal=682,528,918,388"]
const SCENE := "res://scenes/levels/tronco_4.tscn"
## Tronco 4 "La ventana": J1 sube en zigzag hasta su repisa; J2 cae por un pozo, pasa por debajo
## del muro y sube al otro lado. Cada uno cruza con su gancho por debajo de su cortina (J2 más
## arriba). Entre la repisa y el muro hay una ranura por la que cabe el extremo. El muro tiene
## una ventana: cada uno halla el largo que lo deja frente a ella (J1 corto, J2 largo) y se
## balancean los dos a la vez para juntarse adentro.
const M := preload("res://tests/solutions/moves.gd")

static func plan(ctx) -> Dictionary:
	var pump: float = ctx.var_f("pump", 1.3)
	var m: float = ctx.var_f("m", 40)
	return {
		"p1": [["wait_floor"], ["rope", 60]] + M.path(1, [[283, 162], [143, 45], [59, 195], [178, 25], [44, 270]]) + [["rope", 170], ["walk_to", 225.0, 4], ["wait", 0.5]] + M.run_jump(1, 1, 280) + M.swing_launch(1, 1, pump, 580, 685)
			+ [["hang", 748], ["rope", ctx.var_f("r1", 160)], ["wait", 1.0], ["sync", "listos"], ["swing", 748, m, 24]],
		"p2": [["wait_floor"], ["rope", 60]] + M.path(2, [["go", 1580], ["go", 1518], ["go", 1580], ["go", 1470], [1410, 1315], [1343, 1445], [1428, 1304], [1323, 1445], [1426, 1340]]) + [["walk_to", 1300.0, 4], ["wait", 0.3], ["walk_to", 1372.0, 4], ["rope", ctx.var_f("rr", 100)], ["wait", 0.5]] + M.run_jump(2, -1, ctx.var_f("jx", 1325)) + M.swing_launch(2, -1, pump, 1020, 915)
			+ [["hang", 852], ["rope", ctx.var_f("r2", 300)], ["wait", 1.0], ["sync", "listos"], ["swing", 852, -m, 24]],
	}
