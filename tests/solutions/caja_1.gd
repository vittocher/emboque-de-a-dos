extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--no=box --goal=540,518,1060,518", "--start=660,100,940,100 --goal=930,168,670,168"]
const SCENE := "res://scenes/levels/caja_1.tscn"
## Caja 1: la pared mide 250, más que cualquier salto. Cada uno parte del lado equivocado de su
## caja GRANDE (120): tiene que saltarla para poder empujarla contra la pared (la de J2 tapa además unas
## púas). Desde la caja se sube a la pared, y de ahí hay un tramo de plataformas distinto para cada uno.
const M := preload("res://tests/solutions/moves.gd")

static func push_until_stuck(i: int, d: int) -> Array:
	var dir := "right" if d == 1 else "left"
	return [["press", dir], ["wait", 0.5], ["until", func(c): return absf(c.p(i).get_real_velocity().x) < 5.0, 8.0], ["release", dir], ["wait", 0.3]]

## Salta derecho al lado de algo alto y se sube.
static func climb(i: int, d: int, from: float, land: float, top_y: float) -> Array:
	var dir := "right" if d == 1 else "left"
	return [["walk_to", from, 3], ["wait", 0.4], ["tap", "jump"],
		["until", func(c): return c.p(i).global_position.y < top_y, 1.2], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - land) * d > 0.0, 1.5], ["release", dir], ["wait_floor"]]

static func plan(ctx) -> Dictionary:
	var m: float = ctx.var_f("m", 50)
	var r: float = ctx.var_f("r", 160)
	return {
		"p1": [["wait_floor"], ["rope", 60]] + climb(1, -1, 340, 290, 650) + [["walk_to", 140, 4], ["wait_floor"]] + push_until_stuck(1, 1)
			+ climb(1, 1, 355, 410, 650) + climb(1, 1, 470, 530, 518)
			+ M.path(1, [[530, 400], [385, 265], [265, 395], ["run", 415, 640]])
			+ [["hang", 752], ["rope", r], ["wait", 0.8], ["sync", "listos"], ["swing", 752, m, 24]],
		"p2": [["wait_floor"], ["rope", 60]] + climb(2, 1, 1390, 1440, 650) + [["walk_to", 1580, 4], ["wait_floor"]] + push_until_stuck(2, -1)
			+ climb(2, -1, 1245, 1190, 650) + climb(2, -1, 1130, 1070, 518)
			+ M.path(2, [[1075, 1225], [1245, 1360], ["over", 1400, 1430], [1488, 1562], [1545, 1350], ["run", 1300, 960]])
			+ [["hang", 848], ["rope", r], ["wait", 0.8], ["sync", "listos"], ["swing", 848, -m, 24]],
	}
