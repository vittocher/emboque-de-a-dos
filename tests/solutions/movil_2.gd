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

static func plan(ctx) -> Dictionary:
	var r: float = ctx.var_f("r", 200)
	var m: float = ctx.var_f("m", 55)
	return {
		"p1": [["wait_floor"], ["rope", 60]] + ride("Ferry", 552, 465, 280, 272) + M.path(1, [[258, 142]])
			+ [["walk_to", 120, 3], ["until", func(c): return c.level.get_node("Lift").position.y < 491.0, 12.0], ["until", func(c): return c.level.get_node("Lift").position.y > 749.0, 12.0], ["walk_to", 48, 4],
			["until", func(c): return c.level.get_node("Lift").position.y < 490.5, 12.0], ["walk_to", 130, 3]] + ride("PlatLeft", 148, 225, 525, 620)
			+ [["rope", 60], ["hang", 694], ["rope", r], ["wait", 0.5], ["sync", "listos"], ["until", func(c): return c.level.get_node("Passing").position.x < 880.0, 8.0], ["until", func(c): return c.level.get_node("Passing").position.x > 976.0, 8.0], ["wait", ctx.var_f("w", 0.0)], ["swing", 692, m, 30]],
		"p2": [["wait_floor"], ["rope", 60]] + M.path(2, [["over", 1235, 1270], ["over", 1415, 1455], ["go", 1560]]) + ride("PlatRight", 1522, 1445, 1175, 1095)
			+ [["rope", 60], ["hang", 1048], ["rope", r], ["wait", 0.5], ["until", func(c): return c.level.get_node("Passing").position.x > 978.0, 8.0],
			["walk_to", 1000, 6], ["press", "left"],
			["until", func(c): return c.p(2).global_position.x - c.level.get_node("Passing").position.x < -60.0, 3.0], ["release", "left"], ["sync", "listos"]],
	}
