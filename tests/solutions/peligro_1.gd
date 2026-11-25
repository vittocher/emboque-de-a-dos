extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--goal=766,398,514,398"]
const SCENE := "res://scenes/levels/peligro_1.tscn"
## Peligro 1: las púas matan al jugador, no al emboque. Dos fosos de púas (el segundo, más
## ancho) con un bloque chico entre ellos; las sopaipillas están abajo: las saca el extremo,
## que sí puede entrar. Al final los extremos cuelgan sobre púas y basta con que uno se
## balancee.
static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var hop := func(from: float, to: float) -> Array:
		return [["walk_to", x.call(from), 4], ["wait", 0.3], ["jump_to", x.call(to)], ["wait_floor"]]
	var fish := func(at: float) -> Array:
		return [["hang", x.call(at)], ["rope", 170], ["wait", 0.8], ["rope", 60], ["wait", 0.4]]
	return [["wait_floor"], ["rope", 60]] + fish.call(132.0) + hop.call(90.0, 258.0) + [["walk_to", x.call(260), 4]] \
		+ fish.call(302.0) + hop.call(255.0, 490.0) + [["hang", x.call(594)], ["rope", ctx.var_f("r", 120)], ["wait", 0.8],
		["sync", "listos"], ["swing", x.call(594), ctx.var_f("m", 50) * d, 20]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
