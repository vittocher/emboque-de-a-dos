extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--remove=BoxSmall --goal=530,570,1060,630", "--remove=BoxBigR --goal=530,570,1060,630", "--start=660,100,940,100 --goal=930,168,670,168"]
const SCENE := "res://scenes/levels/caja_1.tscn"
## Caja 1. J1: salta unas púas con caca colgando (cuerda larga) y llega a un muro de 215, más que
## una caja sola. Escalera de cajas: primero mete la caja grande bajo la repisa baja, contra el muro,
## y después bota la chica desde la repisa para que caiga encima (si la bota antes, cae al suelo
## y ya no hay arreglo). Sube islas con púas y una brasa. J2: en un pasillo de techo bajo (no se
## salta) hay una zanja de fuego: la caja grande la tapa (el fuego solo lo cruzan las cajas) y la
## chica pasa encima hasta el muro; de ahí sube islas con una brasa y púas.
const M := preload("res://tests/solutions/moves.gd")

static func push_until_stuck(i: int, d: int) -> Array:
	var dir := "right" if d == 1 else "left"
	return [["press", dir], ["wait", 0.5], ["until", func(c): return absf(c.p(i).get_real_velocity().x) < 5.0, 10.0], ["release", dir], ["wait", 0.3]]

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
		"p1": [["wait_floor"], ["rope", ctx.var_f("long", 240)], ["wait", 0.3]] + M.path(1, [["over", 120, 180]]) + [["rope", 60, 2]]
			# la grande bajo la repisa, contra el muro
			+ push_until_stuck(1, 1) + [["walk_to", 268.0, 3]]
			# a la repisa; bota la chica, que cae encima de la grande
			+ climb(1, 1, 268, 305, 688) + [["press", "right"], ["until", func(c): return c.p(1).global_position.x > 393.0, 3.0], ["release", "right"], ["wait", 0.6]]
			+ M.path(1, [[396, 443]]) + climb(1, 1, 443, 495, 565)
			+ M.path(1, [[480, 370], [340, 250], [270, 375], [360, 225], [250, 400], ["run", 440, 640]])
			+ [["hang", 752], ["rope", r], ["wait", 0.8], ["sync", "listos"], ["swing", 752, m, 24]],
		"p2": [["wait_floor"], ["rope", 60], ["press", "left"], ["until", func(c): return c.p(2).global_position.x < 1345.0, 4.0], ["release", "left"], ["wait", 0.8],
			["walk_to", 1450.0, 4], ["wait", 0.3],
			["press", "right"], ["tap", "jump"], ["until", func(c): return c.p(2).global_position.x > 1570.0, 2.0], ["release", "right"], ["wait_floor"]] + push_until_stuck(2, -1)
			+ climb(2, -1, 1186, 1140, 724) + climb(2, -1, 1130, 1060, 634)
			+ M.path(2, [[1090, 1250], [1400, 1470], [1450, 1345], [1360, 1495], [1470, 1300], [1265, 1150], [1110, 960]])
			+ [["hang", 848], ["rope", r], ["wait", 0.8], ["sync", "listos"], ["swing", 848, -m, 24]],
	}
