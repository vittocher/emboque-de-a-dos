extends RefCounted
const CONTROLS := ["12"]
const SCENE := "res://scenes/level_2.tscn"
const SHORTCUTS := ["--no=hook --goal=720,550,860,550", "--start=720,500,860,500 --goal=860,550,720,550"]
## "La T" (equipo; rehecho sobre level_base_large). J1 sube en zigzag (salta unas púas con la cuerda
## larga, a través de la caca) hasta la plataforma media, engancha el gancho de abajo (le baja el
## extremo), sale por el borde y se balancea por debajo hasta la T. J2 sube en zigzag, cruza
## el puente de caca con el extremo por debajo y se engancha para pasar bajo la cortina, sobre el
## fuego. Cada uno baja su extremo por su borde de la T y lo arrastra por debajo hasta el muro.
const M := preload("res://tests/solutions/moves.gd")

static func jump_at(i: int, d: int, from: float, to: float) -> Array:
	return [["press", "right" if d > 0 else "left"], ["until", func(c): return (c.p(i).global_position.x - from) * d > 0.0, 2.0], ["leap_to", to], ["wait_floor"]]

static func plan(ctx) -> Dictionary:
	return {
		"p1": [["wait_floor"], ["rope", 60]] + M.path(1, [[143, 290], [335, 405], [393, 300]]) + [["walk_to", 330.0, 3], ["rope", ctx.var_f("long", 200)], ["wait", 0.4]] + jump_at(1, -1, ctx.var_f("sx", 300), 112) + [["rope", 60, 2]] + M.path(1, [[112, 35], [48, 195], [208, 465]])
			+ [["hang", ctx.var_f("x1", 433)],
			["rope", ctx.var_f("mid", 115)], ["until", func(c): return c.hooked(1), 4.0], ["press", "left"],
			["until", func(c): return not c.p(1).is_on_floor(), 2.0], ["release", "left"],
			["rope", ctx.var_f("swing", 120)], ["pump", ctx.var_f("pump1", 1.5)],
			["until", func(c): return c.p(1)._swing_omega < -0.3, 4.0],
			["until", func(c): return c.p(1)._swing_omega > 0.0 and c.p(1).global_position.x > ctx.var_f("rx1", 520), 6.0],
			["tap", "jump"], ["press", "right"],
			["until", func(c): return c.p(1).global_position.x > 690.0 or c.p(1).is_on_floor(), 3.0],
			["release", "right"], ["wait_floor"], ["rope", 60], ["hang", 612.0],
			["rope", ctx.var_f("m1", 190)], ["wait", 0.8],
			["walk_to", 750],
			["sync", "listos"], ["swing", 750, ctx.var_f("b1", 65), 24]],
		"p2": [["wait_floor"], ["rope", 60]] + M.path(2, [[1529, 1440], [1453, 1560], [1548, 1435], [1453, 1565], [1553, 1440], [1458, 1565], [1553, 1462]]) + [["walk_to", 1398.0, 3], ["wait", 0.6], ["rope", ctx.var_f("under", 125)], ["wait", 0.6], ["walk_to", 1160.0, 4], ["until", func(c): return c.hooked(2), 1.5], ["rope", ctx.var_f("l2", 150)], ["press", "left"], ["until", func(c): return not c.on_floor(2), 2.0], ["release", "left"], ["wait", 0.4], ["rope", ctx.var_f("l2", 150)], ["pump", ctx.var_f("pump", 1.2)],
			["until", func(c): return c.p(2)._swing_omega > 0.3, 4.0],
			["until", func(c): return c.p(2)._swing_omega < 0.0 and c.p(2).global_position.x < ctx.var_f("rx", 965), 6.0],
			["tap", "jump"], ["press", "left"], ["until", func(c): return c.p(2).global_position.x < 870.0 or c.p(2).is_on_floor(), 3.0],
			["release", "left"], ["wait_floor"], ["rope", 60], ["hang", 922.0], ["rope", ctx.var_f("m2", 190)], ["wait", 0.8],
			["walk_to", 834], ["sync", "listos"], ["swing", 834, -ctx.var_f("b2", 65), 24]],
	}
