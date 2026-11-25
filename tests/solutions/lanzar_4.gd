extends RefCounted
const SHORTCUTS := ["--no=throw --goal=450,728,1150,628", "--no=throw --start=690,450,930,560"]
const SCENE := "res://scenes/levels/lanzar_4.tscn"
## Lanzar 4 "Buzón": J1 baja por un pozo (púas con caca colgando:
## cuerda larga; pasillo de caca: con el extremo en la mano; brasa: cuerda corta) hasta el buzón de la izquierda y lanza
## derecho (0°: apenas empieza a apuntar) por la ranura: su extremo cae en la placa que abre la
## compuerta de J2. J2, que subió por unas repisas sobre púas, pasa y lanza el suyo por un nicho lleno
## de púas (a él lo matan; al extremo no): la placa del fondo abre la de J1. Cada uno recoge su extremo. J1
## sube a su repisa y cuelga la campana detrás de la ranura del muro; J2 le lanza el palito por la ranura.
const M := preload("res://tests/solutions/moves.gd")

static func plan(ctx) -> Dictionary:
	var throws := []
	for k in 6:
		throws += [["walk_to", ctx.var_f("tx2", 898), 3], ["until", func(c): return c.e(2)._throw_state == 0, 1.0], ["tap", "throw"],
			["until", func(c): return c.e(2)._throw_state == 1, 2.0], ["walk_to", ctx.var_f("tx2", 898), 3], ["tap", "left"], ["wait", 0.1],
			["tap", "throw"], ["until", func(c): return c.e(2)._throw_state == 2, 1.0],
			["until", func(c): return pingpong(c.e(2)._aim_time * c.e(2).aim_sweep_speed_deg, c.e(2).aim_max_angle_deg) >= ctx.var_f("aim", 13) - 0.5, 3.0],
			["tap", "throw"], ["wait", 0.6], ["until", func(c): return c.won(), 0.9]]
	return {
		"p1": [["wait_floor"], ["rope", ctx.var_f("long", 220)], ["wait", 0.4]] + [["hold_jump", ctx.var_f("h", 0.5)]] + M.path(1, [[124, 288], ["go", 350]]) + [["hold_jump", 0.5], ["rope", 60, 1], ["wait", 0.3], ["tap", "pull"], ["until", func(c): return c.e(1)._throw_state == 1, 1.0]] + M.path(1, [["go", 115]]) + [["tap", "release"], ["wait", 0.5]] + M.path(1, [["over", 182, 208], [270, 362], ["go", 300]])
			+ [["walk_to", ctx.var_f("tx", 250), 3], ["wait", 0.4]] + M.throw_at(1, -1, ctx.var_f("deg", 0.0))
			+ [["wait", 1.0], ["until", func(c): return c.level.get_node("GateLeft").is_open, 30.0], ["rope", 60, 1], ["wait", 0.8], ["walk_to", 440.0, 3], ["sync", "j1_paso"]]
			+ M.path(1, [[462, 565], [555, 465], ["run", 480, 680]])
			+ [["wait", 0.4], ["tap", "pull"], ["until", func(c): return c.e(1)._throw_state == 1, 1.0], ["walk_to", ctx.var_f("e", 732), 2], ["wait", 0.3], ["tap", "release"], ["wait", 0.4], ["rope", ctx.var_f("r", 85)],
			["wait", 1.0], ["sync", "blanco"]],
		"p2": [["wait_floor"], ["rope", 60]] + M.path(2, [[1495, 1395], [1410, 1520], [1505, 1400], [1360, 1282]])
			+ [["until", func(c): return c.level.get_node("GateRight").is_open, 30.0], ["wait", 0.6], ["walk_to", 1185, 4], ["wait_floor"], ["wait", 0.4], ["walk_to", 1185, 3]]
			+ M.throw_at(2, 1, 0.0) + [["sync", "j1_paso"], ["wait", 0.3], ["tap", "throw"], ["until", func(c): return c.e(2)._throw_state == 1, 3.0], ["tap", "release"], ["wait", 0.4]]
			+ M.path(2, [["over", 1095, 1060]]) + [["sync", "blanco"], ["wait", 1.0]] + throws,
	}
