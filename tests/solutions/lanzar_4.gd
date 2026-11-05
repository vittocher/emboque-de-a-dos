extends RefCounted
const SCENE := "res://scenes/levels/lanzar_4.tscn"
## Lanzar 4 "Buzón": J1 lanza su extremo derecho (0°: apenas empieza a apuntar)
## por la ranura de la pared izquierda; cae en la placa amarilla del buzón, que
## abre la compuerta de J2. J2 entra y se para en la placa azul, que abre la de
## J1. J1 recoge el extremo (sale por sobre el borde del buzón) y entra. Cada uno,
## de a uno, acorta al mínimo, se para sobre la ranura del medio (el extremo cae
## por ella) y suelta cuerda hasta el cuenco de abajo.
const M := preload("res://tests/solutions/moves.gd")

## Acorta ANTES de pararse sobre la ranura (recogido desde lejos, el extremo
## sale volando y se pasa de largo); sobre la ranura cae solo, y se suelta cuerda.
static func drop(i: int, back_dir: int, ctx) -> Array:
	return [["rope", 60, 1], ["wait", 0.8], ["walk_to", 640.0, 2], ["wait", 0.6],
		["rope", ctx.var_f("r%d" % i, 195)], ["wait", 0.5], ["walk_to", 640.0 + back_dir * ctx.var_f("back", 20), 3]]

static func plan(ctx) -> Dictionary:
	return {
		"p1": [["wait_floor"], ["walk_to", 130.0, 3], ["wait", 0.3], ["tap", "jump"], ["wait_floor"],
			["walk_to", ctx.var_f("tx", 250), 3], ["wait", 0.4]] + M.throw_at(1, -1, ctx.var_f("deg", 0.0))
			+ [["wait", 1.0], ["sync", "buzon"], ["sync", "placa"], ["rope", 60, 1], ["wait", 0.5],
			["walk_to", 600.0, 3]] + drop(1, -1, ctx) + [["sync", "uno"], ["wait", 1.0], ["jiggle", 610.0, -10, 10]],
		"p2": [["wait_floor"], ["walk_to", 1010.0, 3], ["wait", 0.3], ["tap", "jump"], ["wait_floor"],
			["sync", "buzon"], ["rope", 60, 1], ["wait", 0.8], ["walk_to", 480.0, 3], ["wait", 0.5], ["tap", "jump"], ["wait_floor"], ["walk_to", 480.0, 3],
			["sync", "placa"], ["until", func(c): return c.p(1).global_position.x > 560.0, 8.0]]
			+ [["sync", "uno"]] + drop(2, 1, ctx) + [["jiggle", 670.0, 10, 10]],
	}
