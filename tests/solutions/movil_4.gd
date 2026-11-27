extends RefCounted
const CONTROLS := ["12", "1", "2"]
const SHORTCUTS := ["--start=320,730,1400,730 --goal=688,318,912,318 --remove=LiftLeftA,LiftRightA", "--start=350,730,1250,730 --goal=1250,768,350,768"]
const SCENE := "res://scenes/levels/movil_4.tscn"
## Movil 4 "Contratiempo": J1 baja en un carro que va y viene por encima de un piso de púas (el
## extremo puede arrastrar por ellas), pasa caminando bajo una caca y salta unas púas con la cuerda
## larga. J2 sube en un ascensor esquivando las púas de las paredes, salta otras púas con la cuerda
## larga y baja a saltar una brasa con la cuerda corta. Después, dos ascensores por lado que suben y
## bajan a contratiempo sobre el fuego: con la cuerda corta (larga, el extremo cuelga al fuego
## cuando el ascensor está abajo), cada uno espera el de abajo, sube, se cambia al otro cuando están
## a la misma altura, sube y pasa a la plataforma del medio cuando está arriba. Las dos del medio
## van al revés (una sube y la otra baja): colgando los extremos hacia el muro y balanceándose los
## dos a la vez, se embocan al cruzarse.
const M := preload("res://tests/solutions/moves.gd")

static func y(c, n: String) -> float:
	return c.level.get_node(n).position.y

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return 160.0 + (v if d == 1 else 1280.0 - v)
	var a := "LiftLeftA" if d == 1 else "LiftRightA"
	var b := "LiftLeftB" if d == 1 else "LiftRightB"
	var g := "GoalLeft" if d == 1 else "GoalRight"
	var edge: float = x.call(585)
	return [["rope", ctx.var_f("short", 60), 1], ["walk_to", 320.0 if d == 1 else 1240.0, 3],
		["until", func(c): return y(c, a) < 780.0, 12.0], ["until", func(c): return y(c, a) > 808.0, 12.0], ["walk_to", x.call(300), 3],
		["until", func(c): return y(c, a) < 650.0, 6.0], ["tap", "jump"], ["wait_floor"],
		["until", func(c): return y(c, a) < 581.0 and c.level.get_node(a)._wait > 0.45, 12.0],
		["walk_to", x.call(425), 3],
		["until", func(c): return y(c, b) < 351.0 and c.level.get_node(b)._wait > 0.1 and y(c, g) < 365.0, 60.0],
		["walk_to", edge, 3], ["wait", 0.5], ["rope", ctx.var_f("r", 180)], ["wait", 0.6], ["sync", "listos"],
		["swing", edge, 50 * d, 24]]

static func jump_at(i: int, d: int, from: float, to: float) -> Array:
	return [["press", "right" if d > 0 else "left"], ["until", func(c): return (c.p(i).global_position.x - from) * d > 0.0, 2.0], ["leap_to", to], ["wait_floor"]]

static func plan(ctx) -> Dictionary:
	var long: float = ctx.var_f("long", 215)
	var cart := func(c) -> float: return c.level.get_node("CartL").position.x
	var lift := func(v: float) -> Array: return [["until", func(c): return c.p(2).global_position.y < v, 15.0]]
	return {
		"p1": [["wait_floor"], ["rope", 60], ["walk_to", 50, 3], ["until", func(c): return cart.call(c) > 150.0, 10.0], ["until", func(c): return cart.call(c) < 122.0, 10.0], ["walk_to", 120, 5],
			["wait_floor"], ["until", func(c): return cart.call(c) > 285.0, 10.0], ["walk_to", 368, 3], ["wait_floor"], ["walk_to", 60, 4], ["wait_floor"],
			["walk_to", 30, 4], ["rope", long], ["wait", 0.3], ["walk_to", 24, 4], ["wait", 0.3]] + jump_at(1, 1, ctx.var_f("sx1", 125), 320) + side(1, 1, ctx),
		"p2": [["wait_floor"], ["rope", 60], ["walk_to", 1514, 3]] + lift.call(ctx.var_f("a", 590)) + [["walk_to", 1577, 3]] + lift.call(ctx.var_f("b", 410)) + [["walk_to", 1514, 3]]
			+ lift.call(299) + [["rope", long], ["wait", 0.2]] + jump_at(2, -1, ctx.var_f("sx2", 1485), 1325) + [["rope", 60, 2], ["walk_to", 1250, 5], ["wait_floor"], ["walk_to", 1432, 5], ["wait_floor"]] + M.path(2, [[1432, 1255]]) + side(2, -1, ctx)}
