extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--no=box --goal=960,148,800,808", "--remove=BoxBig --goal=960,148,20,20", "--start=980,80,1230,100 --goal=1230,168,980,148"]
const SCENE := "res://scenes/levels/caja_3.tscn"
const M := preload("res://tests/solutions/moves.gd")

## Caja 3 "Encomienda": J1 sube unas islas sobre el fuego hasta sus cajas. J2 está abajo, frente a un foso de púas de 470 px. J1, arriba, tiene
## una caja chica y una grande: solo la chica cabe por el pozo (el fuego mata a los jugadores,
## no a las cajas) y cae justo en el medio de las púas: J2 la usa de piedra de paso. Con la
## grande, J1 sube su pared de 250. J2 sube una escalera sobre púas. Arriba, los extremos
## cuelgan a distinta altura.
static func climb(i: int, d: int, from: float, land: float, top_y: float) -> Array:
	var dir := "right" if d == 1 else "left"
	return [["walk_to", from, 4], ["wait", 0.4], ["tap", "jump"],
		["until", func(c): return c.p(i).global_position.y < top_y, 1.2], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - land) * d > 0.0, 1.5], ["release", dir], ["wait_floor"]]

static func plan(ctx) -> Dictionary:
	var m: float = ctx.var_f("m", 45)
	# Salto con carrera: parte 70 px antes del borde.
	var hop := func(from: float, to: float) -> Array:
		var d := 1 if to > from else -1
		var dir := "right" if d == 1 else "left"
		return [["walk_to", from - 60.0 * d, 4], ["wait", 0.5], ["press", dir], ["until", func(c): return (c.p(2).global_position.x - from) * d > 0.0, 2.0],
			["jump_to", to], ["wait_floor"]]
	return {
		"p1": [["wait_floor"], ["rope", 60]] + M.path(1, [[115, 225], [265, 370], [350, 235], [265, 370], [415, 660]]) + [["walk_to", 700, 4], ["press", "left"],
			["until", func(c): return c.level.get_node("BoxSmall").position.y > 470.0, 6.0], ["release", "left"], ["walk_to", 640, 4],
			["press", "right"], ["wait", 0.6], ["until", func(c): return absf(c.p(1).get_real_velocity().x) < 5.0, 6.0], ["release", "right"], ["wait", 0.3]]
			+ climb(1, 1, 745, 800, 283) + climb(1, 1, 865, 925, 150)
			+ [["hang", 1054], ["rope", ctx.var_f("r1", 150)], ["wait", 0.8], ["sync", "listos"], ["swing", 1054, m, 24]],
		"p2": [["wait_floor"], ["rope", 60], ["until", func(c): return c.level.get_node("BoxSmall").position.y > 830.0, 30.0], ["wait", 0.5]]
			+ hop.call(200, 485) + [["walk_to", 485, 3], ["wait", 0.4], ["press", "right"], ["wait", 0.07], ["jump_to", 740], ["wait_floor"]] + hop.call(975, 1110) + hop.call(1140, 1290) + hop.call(1320, 1470)
			+ hop.call(1430, 1330) + hop.call(1345, 1480) + hop.call(1450, 1300)
			+ [["hang", 1146], ["rope", ctx.var_f("r2", 130)], ["wait", 0.8], ["sync", "listos"], ["swing", 1146, -m, 24]],
	}
