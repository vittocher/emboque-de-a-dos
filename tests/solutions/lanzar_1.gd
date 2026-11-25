extends RefCounted
const SHORTCUTS := ["--no=throw --goal=480,256,800,378", "--start=480,168,800,290 --goal=800,378,480,256"]
const SCENE := "res://scenes/levels/lanzar_1.tscn"
## Lanzar 1: la torre no se alcanza saltando. Cada uno toma su extremo, lo lanza
## al gancho de su lado, sube tirando de la cuerda y salta arriba de la torre. La meta es un
## tiro: J1 cuelga la campana por el borde (cuerda corta) y J2, más abajo, le lanza el palito
## con poco ángulo, por debajo del muro.
const M := preload("res://tests/solutions/moves.gd")

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var dir := "right" if d == 1 else "left"
	return [["wait_floor"], ["walk_to", x.call(ctx.var_f("tx", 230)), 3], ["wait", 0.5]] \
		+ M.throw_at(i, d, ctx.var_f("deg", 55)) \
		+ [["until", func(c): return c.hooked(i), 1.5], ["rope", 60, 2], ["wait", 0.4],
		["tap", "jump"], ["press", dir], ["until", func(c): return c.p(i).is_on_floor() \
			and (c.p(i).global_position.x - x.call(440)) * d > 0.0, 3.0], ["release", dir], ["wait_floor"], ["walk_to", x.call(480), 4]]

static func plan(ctx) -> Dictionary:
	var throws := []
	for k in 6:
		# Recoge el palito (lanzar), apunta y lanza; si falla, lo vuelve a recoger.
		throws += [["walk_to", 775.0, 3], ["until", func(c): return c.e(2)._throw_state == 0, 1.0], ["tap", "throw"],
			["until", func(c): return c.e(2)._throw_state == 1, 2.0], ["walk_to", 775.0, 3], ["tap", "left"], ["wait", 0.1],
			["tap", "throw"], ["until", func(c): return c.e(2)._throw_state == 2, 1.0],
			["until", func(c): return pingpong(c.e(2)._aim_time * c.e(2).aim_sweep_speed_deg, c.e(2).aim_max_angle_deg) >= ctx.var_f("aim", 11) - 0.5, 3.0],
			["tap", "throw"], ["wait", 0.6], ["until", func(c): return c.won(), 0.9]]
	return {
		"p1": side(1, 1, ctx) + [["hang", 543.0], ["tap", "release"], ["wait", 0.2], ["rope", ctx.var_f("r", 80)], ["wait", 1.0], ["sync", "blanco"]],
		"p2": side(2, -1, ctx) + [["sync", "blanco"], ["wait", 2.0]] + throws,
	}
