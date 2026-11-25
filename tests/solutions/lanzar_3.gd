extends RefCounted
const SHORTCUTS := ["--no=hook --goal=470,448,1130,568", "--no=throw --goal=470,448,1130,568", "--no=hook --start=470,380,1130,500 --goal=650,188,950,308", "--no=throw --start=470,380,1130,500 --goal=650,188,950,308"]
const SCENE := "res://scenes/levels/lanzar_3.tscn"
## Lanzar 3: cada repisa está 260 px más arriba que la anterior (no se alcanza saltando):
## cada uno lanza su extremo al gancho bajo, sube la cuerda, se columpia sobre el fuego y
## salta a la repisa del medio; desde ahí lanza al gancho alto, sube y salta a su isla.
## La isla de J1 está más alta: cuelga la campana por el borde y J2 le lanza el palito
## por encima del vacío (tiro al blanco).
const M := preload("res://tests/solutions/moves.gd")

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1600.0 - v
	var dir := "right" if d == 1 else "left"
	return [["wait_floor"], ["walk_to", x.call(ctx.var_f("tx", 120)), 3], ["wait", 0.5]] 		+ M.throw_at(i, d, ctx.var_f("deg", 53)) 		+ [["until", func(c): return c.hooked(i), 1.5], ["rope", ctx.var_f("len", 100), 2], ["pump", ctx.var_f("pump", 1.5)],
		["until", func(c): return c.p(i)._swing_omega * d < -0.3, 4.0],
		["until", func(c): return c.p(i)._swing_omega * d > 0.0 and (c.p(i).global_position.x - x.call(ctx.var_f("rx", 330))) * d > 0.0, 6.0],
		["tap", "jump"], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(465)) * d >= 0.0 or c.p(i).is_on_floor(), 3.0],
		["release", dir], ["wait_floor"], ["rope", 60, 1], ["walk_to", x.call(480), 3], ["wait", 0.5], ["walk_to", x.call(ctx.var_f("tx2", 430)), 3], ["wait", 0.6]] 		+ M.throw_at(i, d, ctx.var_f("deg2", 57)) 		+ [["until", func(c): return c.hooked(i), 1.5], ["rope", 60, 2], ["wait", 0.5], ["tap", "jump"], ["press", dir],
		["until", func(c): return c.p(i).is_on_floor() and (c.p(i).global_position.x - x.call(590)) * d > 0.0, 3.0], ["release", dir],
		["wait_floor"], ["walk_to", x.call(650), 4], ["do", func(c): print("ISLA p", i, " ", c.p(i).global_position)]]

static func plan(ctx) -> Dictionary:
	var throws := []
	for k in 5:
		# Recoge el palito (lanzar), apunta y lanza; si falla, lo vuelve a recoger.
		throws += [["walk_to", 902.0, 3], ["until", func(c): return c.e(2)._throw_state == 0, 1.0], ["tap", "throw"],
			["until", func(c): return c.e(2)._throw_state == 1, 2.0], ["walk_to", 902.0, 3], ["tap", "left"], ["wait", 0.1],
			["tap", "throw"], ["until", func(c): return c.e(2)._throw_state == 2, 1.0],
			["until", func(c): return pingpong(c.e(2)._aim_time * c.e(2).aim_sweep_speed_deg, c.e(2).aim_max_angle_deg) >= ctx.var_f("aim", 4) - 0.5, 3.0],
			["tap", "throw"], ["wait", 0.6], ["until", func(c): return c.won(), 0.9]]
	return {
		"p1": side(1, 1, ctx) + [["hang", 711.0], ["rope", ctx.var_f("r", 110)], ["wait", 1.0], ["sync", "blanco"]],
		"p2": side(2, -1, ctx) + [["walk_to", 902.0, 3], ["sync", "blanco"], ["wait", 4.0]] + throws,
	}
