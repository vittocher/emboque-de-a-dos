extends RefCounted
const SCENE := "res://scenes/level_2.tscn"
## Nivel 2 "La T" (equipo). J1 baja a la plataforma media a la izquierda de
## las púas, engancha el gancho de abajo (tirar, soltar un poco, tirar), sale por
## el borde, hace rapel y se balancea por debajo hasta la T. J2 acorta la cuerda
## (con 120 el palito toca el bloque de fuego), corre a la izquierda, engancha
## el gancho derecho y salta a la T. Cada uno baja su extremo por su borde de
## la T y lo arrastra por debajo hasta el muro, donde se juntan.
static func plan(ctx) -> Dictionary:
	var r2: float = ctx.var_f("r2", 80)
	return {
		"p1": [["wait_floor"], ["walk_to", ctx.var_f("x1", 310), 4], ["wait_floor"], ["wait", 0.6],
			["rope", 60], ["wait", 0.4], ["rope", ctx.var_f("mid", 110)], ["wait", 0.4], ["rope", 60],
			["until", func(c): return c.hooked(1), 1.5], ["press", "left"],
			["until", func(c): return not c.p(1).is_on_floor(), 2.0], ["release", "left"],
			["rope", ctx.var_f("swing", 170)], ["pump", ctx.var_f("pump1", 1.5)],
			["until", func(c): return c.p(1)._swing_omega < -0.3, 4.0],
			["until", func(c): return c.p(1)._swing_omega > 0.0 and c.p(1).global_position.x > ctx.var_f("rx1", 400), 6.0],
			["tap", "jump"], ["press", "right"],
			["until", func(c): return c.p(1).global_position.x > 540.0 or c.p(1).is_on_floor(), 3.0],
			["release", "right"], ["wait_floor"], ["rope", 60], ["walk_to", 498, 4], ["wait", 0.5],
			["rope", ctx.var_f("m1", 175)], ["wait", 0.8],
			["walk_to", 600],
			["sync", "listos"], ["jiggle", 600, ctx.var_f("b1", 60), 15]],
		"p2": [["wait_floor"], ["rope", r2], ["press", "left"],
			["until", func(c): return c.hooked(2), 3.0], ["release", "left"], ["pump", ctx.var_f("pump", 0.6)],
			["until", func(c): return c.p(2)._swing_omega > 0.3, 4.0],
			["until", func(c): return c.p(2)._swing_omega < 0.0 and c.p(2).global_position.x < ctx.var_f("rx", 880), 6.0],
			["tap", "jump"], ["press", "left"], ["until", func(c): return c.p(2).global_position.x < 700.0 or c.p(2).is_on_floor(), 3.0],
			["release", "left"], ["wait_floor"], ["walk_to", 758, 4], ["rope", ctx.var_f("m2", 175)], ["wait", 0.8],
			["walk_to", 664], ["sync", "listos"], ["jiggle", 664, -ctx.var_f("b2", 60), 15]],
	}
