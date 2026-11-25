extends RefCounted
const SHORTCUTS := ["--no=throw --goal=528,418,20,20", "--start=528,350,760,450 --goal=760,528,528,418"]
const SCENE := "res://scenes/levels/lanzar_4.tscn"
## Lanzar 4 "Buzón": J1 lanza su extremo derecho (0°: apenas empieza a apuntar)
## por la ranura de la pared izquierda; cae en la placa amarilla del buzón, que
## abre la compuerta de J2. J2 entra y se para en la placa azul, que abre la de
## J1. J1 recoge el extremo (sale por sobre el borde del buzón) y entra. En la meta hay otro
## buzón: un muro con una ranura. J1 sube a su repisa y cuelga la campana justo detrás de
## ella; J2 le lanza el palito por la ranura.
const M := preload("res://tests/solutions/moves.gd")

static func plan(ctx) -> Dictionary:
	var throws := []
	for k in 6:
		throws += [["walk_to", ctx.var_f("tx2", 738), 3], ["until", func(c): return c.e(2)._throw_state == 0, 1.0], ["tap", "throw"],
			["until", func(c): return c.e(2)._throw_state == 1, 2.0], ["walk_to", ctx.var_f("tx2", 738), 3], ["tap", "left"], ["wait", 0.1],
			["tap", "throw"], ["until", func(c): return c.e(2)._throw_state == 2, 1.0],
			["until", func(c): return pingpong(c.e(2)._aim_time * c.e(2).aim_sweep_speed_deg, c.e(2).aim_max_angle_deg) >= ctx.var_f("aim", 13) - 0.5, 3.0],
			["tap", "throw"], ["wait", 0.6], ["until", func(c): return c.won(), 0.9]]
	return {
		"p1": [["wait_floor"], ["walk_to", 130.0, 3], ["wait", 0.3], ["tap", "jump"], ["wait_floor"],
			["walk_to", ctx.var_f("tx", 250), 3], ["wait", 0.4]] + M.throw_at(1, -1, ctx.var_f("deg", 0.0))
			+ [["wait", 1.0], ["sync", "buzon"], ["sync", "placa"], ["rope", 60, 1], ["wait", 0.5],
			["walk_to", 440.0, 3], ["wait", 0.5], ["jump_to", 520], ["wait_floor"], ["wait", 0.4], ["tap", "pull"], ["until", func(c): return c.e(1)._throw_state == 1, 1.0], ["walk_to", ctx.var_f("e", 572), 2], ["wait", 0.3], ["tap", "release"], ["wait", 0.4], ["rope", ctx.var_f("r", 85)],
			["wait", 1.0], ["sync", "blanco"]],
		"p2": [["wait_floor"], ["walk_to", 1010.0, 3], ["wait", 0.3], ["tap", "jump"], ["wait_floor"],
			["sync", "buzon"], ["rope", 60, 1], ["wait", 0.8], ["walk_to", 815.0, 3], ["wait", 0.8],
			["sync", "placa"], ["until", func(c): return c.p(1).global_position.x > 435.0, 8.0], ["sync", "blanco"], ["wait", 1.0]] + throws,
	}
