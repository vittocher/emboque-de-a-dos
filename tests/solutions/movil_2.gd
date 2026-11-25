extends RefCounted
const CONTROLS := ["12", "1"]
const SHORTCUTS := ["--remove=PlatLeft,PlatRight --goal=630,448,1090,448", "--start=630,380,1090,380 --goal=1000,448,630,448"]
const SCENE := "res://scenes/levels/movil_2.tscn"
## Movil 2 "Vaivén": el techo bajo no deja saltar el foso; hay que cruzarlo en la plataforma
## que va y viene, con la cuerda corta (la caca está justo debajo). En la meta, J1 está en
## una repisa fija y J2 en otra plataforma que pasa: los extremos se encuentran "al pasar",
## si J1 se balancea a tiempo.
static func ride(i: int, d: int, plat: String, wait_x: float, near_x: float, far_x: float, out_x: float) -> Array:
	return [["walk_to", wait_x, 3], ["until", func(c): return absf(c.level.get_node(plat).position.x - far_x) < 3.0, 12.0],
		["until", func(c): return absf(c.level.get_node(plat).position.x - near_x) < 3.0, 12.0], ["walk_to", near_x, 8],
		["until", func(c): return absf(c.level.get_node(plat).position.x - far_x) < 3.0, 12.0], ["walk_to", out_x, 4]]

static func plan(ctx) -> Dictionary:
	var r: float = ctx.var_f("r", 170)
	var m: float = ctx.var_f("m", 45)
	return {
		"p1": [["wait_floor"], ["rope", 80]] + ride(1, 1, "PlatLeft", 78, 155, 525, 620)
			+ [["rope", 60], ["hang", 694], ["rope", r], ["wait", 0.5], ["sync", "listos"], ["swing", 692, m, 30]],
		"p2": [["wait_floor"], ["rope", 80]] + ride(2, -1, "PlatRight", 1522, 1445, 1175, 1095)
			+ [["rope", 60], ["hang", 1048], ["rope", r], ["wait", 0.5], ["until", func(c): return c.level.get_node("Passing").position.x > 978.0, 8.0],
			["until", func(c): return c.level.get_node("Passing").position.x > 978.0, 8.0], ["walk_to", 1000, 6], ["press", "left"],
			["until", func(c): return c.p(2).global_position.x - c.level.get_node("Passing").position.x < -60.0, 3.0], ["release", "left"], ["sync", "listos"]],
	}
