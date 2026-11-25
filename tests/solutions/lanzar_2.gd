extends RefCounted
const SHORTCUTS := ["--no=throw --goal=500,418,1100,418", "--no=hook --goal=500,418,1100,418", "--no=throw --start=500,350,1100,350", "--start=500,350,1100,350 --goal=1100,418,500,418"]
const SCENE := "res://scenes/levels/lanzar_2.tscn"
## Lanzar 2 "Puntería": J1 baja por un pasillo con caca y púas, J2 por unas repisas (una, de techo bajo y tapada de caca: con el extremo en la mano). Cada uno lanza al gancho de su lado, sube la cuerda, se columpia sobre
## el fuego y salta a su repisa (270 px más arriba: no se llega saltando). En el medio, un muro
## con un agujero y UN gancho adentro para los dos: cada uno le lanza su extremo desde su
## repisa; con los dos en el mismo gancho, se embocan.
const M := preload("res://tests/solutions/moves.gd")

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1600.0 - v
	var dir := "right" if d == 1 else "left"
	return [["walk_to", x.call(ctx.var_f("tx", 143)), 3], ["wait", 0.5]] \
		+ M.throw_at(i, d, ctx.var_f("deg", 43)) \
		+ [["until", func(c): return c.hooked(i), 1.5], ["rope", ctx.var_f("len", 90), 2], ["pump", ctx.var_f("pump", 1.5)],
		["until", func(c): return c.p(i)._swing_omega * d < -0.3, 4.0],
		["until", func(c): return c.p(i)._swing_omega * d > 0.0 and (c.p(i).global_position.x - x.call(ctx.var_f("rx", 425))) * d > 0.0, 6.0],
		["tap", "jump"], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(505)) * d >= 0.0 or c.p(i).is_on_floor(), 3.0],
		["release", dir], ["wait_floor"], ["walk_to", x.call(571), 3], ["wait", 0.8], ["rope", 60, 1], ["wait", 0.6], ["walk_to", x.call(ctx.var_f("tx2", 535)), 3], ["wait", 0.5]]

static func shoot(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1600.0 - v
	var out := []
	for k in 4:
		out += [["walk_to", x.call(ctx.var_f("tx2", 535)), 3], ["until", func(c): return c.hooked(i) or c.e(i)._throw_state == 0, 1.0], ["tap", "throw"],
			["until", func(c): return c.hooked(i) or c.e(i)._throw_state == 1, 2.0], ["tap", "right" if d == 1 else "left"], ["wait", 0.1], ["tap", "throw"],
			["until", func(c): return c.hooked(i) or c.e(i)._throw_state == 2, 1.0],
			["until", func(c): return c.hooked(i) or pingpong(c.e(i)._aim_time * c.e(i).aim_sweep_speed_deg, c.e(i).aim_max_angle_deg) >= ctx.var_f("aim", 32) - 0.5, 3.0],
			["tap", "throw"], ["wait", 1.0]]
	return out

static func plan(ctx) -> Dictionary:
	return {"p1": [["wait_floor"], ["rope", 60], ["walk_to", 245, 5], ["wait_floor"]] + [["rope", ctx.var_f("long", 220)], ["wait", 0.4]] + M.path(1, [[215, 90], ["go", 42]]) + [["rope", 60], ["wait", 0.4]] + M.path(1, [["over", 115, 148], ["go", 235]]) + side(1, 1, ctx) + [["sync", "listos"]] + shoot(1, 1, ctx),
		"p2": [["wait_floor"], ["rope", 60]] + M.path(2, [["go", 1430]]) + [["rope", 60, 1], ["wait", 0.3], ["tap", "pull"], ["until", func(c): return c.e(2)._throw_state == 1, 1.0]] + M.path(2, [["go", 1560], ["go", 1362], ["go", 1550], ["go", 1465]]) + [["tap", "release"], ["wait", 0.4]] + side(2, -1, ctx) + [["sync", "listos"], ["until", func(c): return c.hooked(1), 10.0], ["wait", 1.0]] + shoot(2, -1, ctx)}
