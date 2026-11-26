extends RefCounted
const SHORTCUTS := ["--no=throw --goal=640,256,960,378", "--no=throw,rope --goal=370,526,20,20", "--start=640,168,960,290 --goal=960,378,640,256"]
const SCENE := "res://scenes/levels/lanzar_1.tscn"
## Lanzar 1: J1 parte frente a un pasillo de caca de techo bajo (no se puede saltar): tiene que
## cruzarlo con el extremo EN LA MANO (la caca no daña al jugador). J2 sube unas islas tapadas de caca: también con el
## extremo en la mano. La torre no se
## alcanza saltando: cada uno lanza su extremo al gancho de su lado, sube tirando de la cuerda y salta
## arriba de la torre. La meta es un tiro: J1 cuelga la campana por el borde (cuerda corta) y J2, más
## abajo, le lanza el palito con poco ángulo, por debajo del muro.
const M := preload("res://tests/solutions/moves.gd")

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1600.0 - v
	var dir := "right" if d == 1 else "left"
	return [["walk_to", x.call(ctx.var_f("tx", 390)), 3], ["wait", 0.5]] \
		+ M.throw_at(i, d, ctx.var_f("deg", 55)) \
		+ [["until", func(c): return c.hooked(i), 1.5], ["rope", 60, 2], ["wait", 0.4],
		["tap", "jump"], ["press", dir], ["until", func(c): return c.p(i).is_on_floor() \
			and (c.p(i).global_position.x - x.call(600)) * d > 0.0, 3.0], ["release", dir], ["wait_floor"], ["walk_to", x.call(640), 4]]

static func plan(ctx) -> Dictionary:
	var throws := []
	for k in 6:
		# Recoge el palito (lanzar), apunta y lanza; si falla, lo vuelve a recoger.
		throws += [["walk_to", 935.0, 3], ["until", func(c): return c.e(2)._throw_state == 0, 1.0], ["tap", "throw"],
			["until", func(c): return c.e(2)._throw_state == 1, 2.0], ["walk_to", 935.0, 3], ["tap", "left"], ["wait", 0.1],
			["tap", "throw"], ["until", func(c): return c.e(2)._throw_state == 2, 1.0],
			["until", func(c): return pingpong(c.e(2)._aim_time * c.e(2).aim_sweep_speed_deg, c.e(2).aim_max_angle_deg) >= ctx.var_f("aim", 13) - 0.5, 3.0],
			["tap", "throw"], ["wait", 0.6], ["until", func(c): return c.won(), 0.9]]
	return {
		"p1": [["wait_floor"], ["rope", 60]] + M.path(1, [[398, 222], [216, 120], [112, 40], [48, 125]]) + [["rope", 60, 1], ["wait", 0.3], ["tap", "pull"], ["until", func(c): return c.e(1)._throw_state == 1, 1.0],
			["walk_to", 370, 4], ["tap", "release"], ["wait", 0.5]] + side(1, 1, ctx) + [["hang", 703.0], ["tap", "release"], ["wait", 0.2], ["rope", ctx.var_f("r", 80)], ["wait", 1.0], ["sync", "blanco"]],
		"p2": [["wait_floor"], ["rope", 60, 1], ["wait", 0.3], ["tap", "pull"], ["until", func(c): return c.e(2)._throw_state == 1, 1.0]] + M.path(2, [[1493, 1402], [1428, 1520], [1505, 1412], [1426, 1528], [1523, 1415], [1411, 1300]]) + side(2, -1, ctx) + [["sync", "blanco"], ["wait", 2.0]] + throws,
	}
