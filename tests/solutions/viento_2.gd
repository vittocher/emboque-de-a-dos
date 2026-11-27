extends RefCounted
const SHORTCUTS := ["--no=wind --start=570,350,1030,350", "--start=570,350,1030,350 --goal=1030,388,570,388", "--remove=Jet --goal=20,20,1030,388"]
const SCENE := "res://scenes/levels/viento_2.tscn"
## Viento 2 "Ventolera": J1 sube tres repisas y cruza un viento en contra en ráfagas (en la
## calma); J2 salta a un chorro que lo sube a su repisa. En la meta los separan 300 px, demasiado
## para balancearse: un viento de costado estira la cuerda de J1 como una bandera hasta donde
## cuelga el palito de J2. Hay que hallar los dos largos.
const V := preload("res://tests/solutions/viento_3.gd")

static func plan(ctx) -> Dictionary:
	# Salto con carrera: parte 45 px antes de [from].
	var hop := func(i: int, from: float, to: float) -> Array:
		var d := 1 if to > from else -1
		return [["walk_to", from - 45.0 * d, 4], ["wait", 0.4], ["press", "right" if d == 1 else "left"],
			["until", func(c): return (c.p(i).global_position.x - from) * d > 0.0, 2.0], ["jump_to", to], ["wait_floor"]]
	var r: float = ctx.var_f("r1", 285)
	return {
		"p1": [["wait_floor"], ["rope", 60]] + hop.call(1, 260, 150) + hop.call(1, 130, 40) + [["walk_to", 25, 4]] + hop.call(1, 70, 235) + [["walk_to", 275, 4]]
			+ V.gust_ends("Headwind") + [["press", "right"], ["wait", 0.06], ["tap", "jump"], ["until", func(c): return c.p(1).global_position.x > 560.0, 3.0],
			["release", "right"], ["wait_floor"], ["walk_to", 640, 3], ["wait", 1.5], ["rope", r], ["wait", 3.0], ["sync", "listos"], ["wait", 4.0], ["rope", r + 15], ["wait", 3.0], ["rope", r + 30], ["wait", 3.0], ["rope", r - 15], ["wait", 3.0]],
		"p2": [["wait_floor"], ["rope", 60]] + hop.call(2, 1492, 1370) + [["walk_to", 1360, 4], ["wait", 0.4], ["press", "left"], ["wait", 0.05], ["tap", "jump"],
			["until", func(c): return c.p(2).global_position.x < 1060.0, 4.0], ["release", "left"], ["wait_floor"],
			["hang", 924], ["rope", ctx.var_f("r2", 150)], ["wait", 0.5], ["sync", "listos"]],
	}
