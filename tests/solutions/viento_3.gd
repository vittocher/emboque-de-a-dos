extends RefCounted
const SHORTCUTS := ["--no=wind --goal=350,558,1250,558", "--remove=WindCenter --start=700,470,880,230"]
const SCENE := "res://scenes/levels/viento_3.tscn"
## Viento 3 "correo aéreo": el viento de los costados sopla en RÁFAGAS (sopla, para). Los
## chorros hacia arriba se toman cuando soplan (una ráfaga sube un piso, no dos); los que
## soplan en contra se cruzan en la calma. J1: un chorro y un viento en contra hasta el
## pasillo. J2: dos pisos de chorro y un viento en contra hasta arriba de la torre. En el
## pozo del medio el viento (constante) levanta la campana de J1; J2 se asoma y baja el
## palito para recibirla. Hay que encontrar los dos largos.
static func gust_starts(node: String) -> Array:
	return [["until", func(c): return c.level.get_node(node).gust_power() <= 0.0, 6.0],
		["until", func(c): return c.level.get_node(node).gust_power() > 0.0, 6.0]]

static func gust_ends(node: String) -> Array:
	return [["until", func(c): return c.level.get_node(node).gust_power() > 0.0, 6.0],
		["until", func(c): return c.level.get_node(node).gust_power() <= 0.0, 6.0]]

## Entra al chorro al empezar la ráfaga, sube hasta top y sale hacia out (px).
static func ride(i: int, jet: String, jet_x: float, jump: bool, top: float, out_x: float) -> Array:
	var d := 1 if out_x > jet_x else -1
	var dir := "right" if d == 1 else "left"
	return gust_starts(jet) + ([["tap", "jump"]] if jump else []) + [["walk_to", jet_x, 12],
		["until", func(c): return c.p(i).global_position.y < top, 2.5], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - out_x) * d > 0.0, 2.0], ["release", dir], ["wait_floor"]]

static func plan(ctx) -> Dictionary:
	return {
		"p1": [["wait_floor"], ["rope", ctx.var_f("rope", 100)], ["walk_to", 115.0, 4]] + ride(1, "JetLeft", 220.0, true, 540.0, 335.0)
			+ [["walk_to", 400.0, 4]] + gust_ends("HeadwindLeft") + [["press", "right"], ["wait", 0.06], ["tap", "jump"],
			["until", func(c): return c.p(1).global_position.x > 640.0, 3.0], ["release", "right"], ["wait_floor"],
			["rope", 60], ["walk_to", ctx.var_f("x1", 766), 3], ["wait", 0.5], ["rope", ctx.var_f("r1", 130)], ["sync", "listos"],
			["wait", 2.0], ["jiggle", ctx.var_f("x1", 766), 12, 20]],
		"p2": [["wait_floor"], ["rope", 100], ["walk_to", 1485.0, 4]] + ride(2, "JetRight", 1380.0, true, 540.0, 1260.0)
			+ [["walk_to", 1275.0, 4]] + ride(2, "JetRight", 1380.0, true, 280.0, 1260.0)
			+ [["walk_to", 1210.0, 4]] + gust_ends("HeadwindRight") + [["press", "left"], ["wait", 0.06], ["tap", "jump"],
			["until", func(c): return c.p(2).global_position.x < 960.0, 3.0], ["release", "left"], ["wait_floor"],
			["walk_to", 800.0, 3], ["rope", 60, 1], ["walk_to", 764.0, 3], ["tap", "jump"], ["wait_floor"], ["wait", 0.5], ["rope", ctx.var_f("r2", 125)], ["sync", "listos"]],
	}
