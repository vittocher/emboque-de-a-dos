extends RefCounted
const SCENE := "res://scenes/levels/viento_2.tscn"
## Viento 2: un muro separa a los dos; abajo tiene una ventana por la que pasa el
## emboque pero no un jugador. Una corriente sopla hacia la ventana desde el
## lado de J1: J1 se acerca y suelta cuerda, y el viento le lleva el extremo
## por la ventana hasta el cuenco hundido del otro lado. J2 baja el suyo al
## cuenco. Debajo del cuenco hay caca: no hay que soltar de más.
static func plan(ctx) -> Dictionary:
	return {
		"p1": [["wait_floor"], ["rope", 60], ["walk_to", ctx.var_f("x1", 560), 4], ["wait", 0.5],
			["rope", ctx.var_f("r1", 215)], ["sync", "listos"], ["until", func(c): return c.won(), 8.0],
			["pump_end", 8.0, ctx.var_f("x1", 560), 20]],
		"p2": [["wait_floor"], ["rope", 60], ["walk_to", 838, 3], ["wait", 0.5], ["rope", ctx.var_f("r2", 120)],
			["sync", "listos"], ["until", func(c): return c.won(), 8.0], ["jiggle", 838, -10, 8]],
	}
