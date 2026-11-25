extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--no=box --goal=600,228,620,648", "--start=1080,270,1330,270 --goal=1330,338,1080,338"]
const SCENE := "res://scenes/level_4.tscn"
## "Escalones" (del equipo), en dos pisos: los dos van hacia la derecha, J1 por arriba y J2 por abajo.
## Cada uno tiene que subir una pared de 160 con una caja grande: J1 parte del lado equivocado de la
## suya. J1 sigue por islas sobre el fuego; J2, por
## islas, caca y un túnel bajo el hueco de la meta, y sube en zigzag al otro lado.
const M := preload("res://tests/solutions/moves.gd")
const C := preload("res://tests/solutions/caja_1.gd")

static func plan(ctx) -> Dictionary:
	var m: float = ctx.var_f("m", 45)
	var r: float = ctx.var_f("r", 150)
	return {
		"p1": [["wait_floor"], ["rope", 60]] + C.climb(1, -1, 270, 225, 306) + [["walk_to", 100, 4], ["wait_floor"]] + C.push_until_stuck(1, 1)
			+ C.climb(1, 1, 448, 505, 306) + C.climb(1, 1, 534, 590, 230)
			+ M.path(1, [[610, 720], [725, 830], ["over", 900, 925], ["go", 1060]])
			+ [["sync", "arriba"], ["hang", 1162], ["rope", r], ["wait", 0.8], ["sync", "listos"], ["swing", 1162, m, 24]],
		"p2": [["wait_floor"], ["rope", 60]] + C.push_until_stuck(2, 1) + C.climb(2, 1, 488, 545, 725) + C.climb(2, 1, 574, 620, 650)
			+ M.path(2, [[625, 730], [735, 880], ["over", 930, 965], ["go", 1090], ["go", 1310], [1325, 1445], [1470, 1560], [1545, 1450], [1470, 1560], [1545, 1450], [1420, 1350]])
			+ [["sync", "arriba"], ["hang", 1258], ["rope", r], ["wait", 0.8], ["sync", "listos"], ["swing", 1258, -m, 24]],
	}
