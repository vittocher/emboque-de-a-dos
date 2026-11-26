extends RefCounted
const CONTROLS := ["12", "1"]
const SHORTCUTS := ["--remove=PlatLeft,PlatRight --goal=630,448,1090,448", "--remove=Ferry --goal=138,708,20,20", "--remove=Lift --goal=135,448,20,20", "--start=630,380,1090,380 --goal=1000,448,630,448"]
const SCENE := "res://scenes/levels/movil_2.tscn"
## Movil 2 "Vaivén": J1 parte abajo: cruza en una plataforma hacia la izquierda, sube en un
## ascensor y vuelve por un pasillo de techo bajo en otra plataforma (con la cuerda corta: la caca está justo
## debajo). J2 va por el techo del pasillo (púas y caca), se deja caer al final y vuelve por abajo, también
## en plataforma. En la meta, J1 está en una repisa fija y J2 en otra plataforma que pasa: los extremos se
## encuentran "al pasar", si J1 se balancea a tiempo.
const M := preload("res://tests/solutions/moves.gd")

static func ride(plat: String, wait_x: float, near_x: float, far_x: float, out_x: float) -> Array:
	return [["walk_to", wait_x, 3], ["until", func(c): return absf(c.level.get_node(plat).position.x - far_x) < 3.0, 12.0],
		["until", func(c): return absf(c.level.get_node(plat).position.x - near_x) < 3.0, 12.0], ["walk_to", near_x, 8],
		["until", func(c): return absf(c.level.get_node(plat).position.x - far_x) < 3.0, 12.0], ["walk_to", out_x, 4]]

## Igual, pero saltando sobre lo que pasa a la altura de la plataforma: en cada x de [param at], salta hacia adelante.
static func ride_over(plat: String, i: int, wait_x: float, near_x: float, far_x: float, out_x: float, at: Array, rope: float) -> Array:
	var d := 1.0 if far_x > near_x else -1.0
	var out := [["walk_to", wait_x, 3], ["until", func(c): return absf(c.level.get_node(plat).position.x - far_x) < 3.0, 12.0],
		["until", func(c): return absf(c.level.get_node(plat).position.x - near_x) < 3.0, 12.0], ["walk_to", near_x - 14.0 * d, 6], ["rope", rope]]
	for x: float in at:
		out += [["until", func(c): return (c.p(i).global_position.x - x) * d > 0.0, 12.0], ["press", "right" if d > 0.0 else "left"], ["tap", "jump"], ["wait", 0.28], ["release", "right" if d > 0.0 else "left"], ["wait_floor"],
			["do", func(_c): pass]]
	return out + [["until", func(c): return absf(c.level.get_node(plat).position.x - far_x) < 3.0, 12.0], ["walk_to", out_x, 4]]

static func plan(ctx) -> Dictionary:
	var r: float = ctx.var_f("r", 170)
	var m: float = ctx.var_f("m", 50)
	return {
		"p1": [["wait_floor"], ["rope", 60]] + ride("Ferry", 552, 465, 280, 272) + M.path(1, [[258, 158]])
			+ [["walk_to", 150, 3], ["until", func(c): return c.level.get_node("Lift").position.y < 491.0, 12.0], ["until", func(c): return c.level.get_node("Lift").position.y > 749.0, 12.0], ["walk_to", 46, 4],
			["until", func(c): return c.level.get_node("Lift").position.y < 490.5, 12.0], ["walk_to", 165, 3], ["wait", 0.3], ["walk_to", 136, 3]] + [["hold_jump", ctx.var_f("hl", 0.5)]] + ride_over("PlatLeft", 1, 136, 225, 525, 620, [ctx.var_f("j1", 290.0)], ctx.var_f("long", 220))
			+ [["rope", 60], ["hang", 694], ["rope", r], ["wait", 0.5], ["sync", "listos"], ["until", func(c): return c.level.get_node("Passing").position.x < 880.0, 8.0], ["until", func(c): return c.level.get_node("Passing").position.x > 976.0, 8.0], ["wait", ctx.var_f("w", 1.2)], ["swing", 692, m, 30]],
		"p2": [["wait_floor"], ["rope", 60]] + [["rope", ctx.var_f("long2", 220)], ["wait", 0.4], ["walk_to", 1150, 5], ["hold_jump", ctx.var_f("h", 0.5)]] + M.path(2, [[1178, 1345], ["go", 1560]]) + [["hold_jump", 0.3], ["rope", 60], ["wait", 0.5]] + ride_over("PlatRight", 2, 1522, 1445, 1175, 1095, [1430.0, 1270.0], 60.0)
			+ [["rope", 60], ["hang", 1048], ["rope", r], ["wait", 0.5], ["until", func(c): return c.level.get_node("Passing").position.x > 978.0, 8.0],
			["walk_to", 1000, 6], ["press", "left"],
			["until", func(c): return c.p(2).global_position.x - c.level.get_node("Passing").position.x < -60.0, 3.0], ["release", "left"], ["sync", "listos"]],
	}
