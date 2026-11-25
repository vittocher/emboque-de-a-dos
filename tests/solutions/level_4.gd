extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--no=box --goal=600,138,620,558", "--start=1080,270,1330,270 --goal=1330,338,1080,338"]
const SCENE := "res://scenes/level_4.tscn"
## "Escalones" (del equipo), en dos pisos: los dos van hacia la derecha, J1 por arriba y J2 por abajo.
## Cada uno tiene que subir una pared de 250 con una caja grande: J1 parte del lado equivocado de la
## suya y la de J2 tapa las púas pegadas a la pared. J1 sigue por islas sobre el fuego; J2, por
## islas, caca y un túnel bajo el hueco de la meta, y sube en zigzag al otro lado.
const M := preload("res://tests/solutions/moves.gd")
const C := preload("res://tests/solutions/caja_1.gd")

static func plan(ctx) -> Dictionary:
	var m: float = ctx.var_f("m", 45)
	var r: float = ctx.var_f("r", 150)
	return {
		"p1": [["wait_floor"], ["rope", 60]] + C.climb(1, -1, 290, 240, 270) + [["walk_to", 100, 4], ["wait_floor"]] + C.push_until_stuck(1, 1)
			+ C.climb(1, 1, 415, 470, 270) + C.climb(1, 1, 530, 590, 138)
			+ M.path(1, [[615, 745], ["run", 752, 872], [885, 940], [960, 1060]])
			+ [["sync", "arriba"], ["hang", 1162], ["rope", r], ["wait", 0.8], ["sync", "listos"], ["swing", 1162, m, 24]],
		"p2": [["wait_floor"], ["rope", 60]] + C.push_until_stuck(2, 1) + C.climb(2, 1, 455, 510, 690) + C.climb(2, 1, 570, 620, 558)
			+ M.path(2, [[625, 735], [765, 865], ["over", 920, 960], ["go", 1090], ["over", 1170, 1220], [1325, 1445], [1470, 1570], [1545, 1445], [1470, 1570], [1550, 1350]])
			+ [["sync", "arriba"], ["hang", 1258], ["rope", r], ["wait", 0.8], ["sync", "listos"], ["swing", 1258, -m, 24]],
	}
