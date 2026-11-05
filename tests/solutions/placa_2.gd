extends RefCounted
const SCENE := "res://scenes/levels/placa_2.tscn"
## Placa 2: la placa abre la compuerta solo mientras algo la pisa, y está lejos
## de la compuerta. Cada uno deja su extremo en la placa (en un rebaje del
## suelo, así no rueda), salta el rebaje con la cuerda larga,
## cruza la compuerta abierta y recoge la cuerda: el extremo pasa por debajo
## mientras la compuerta baja (no aplasta: espera si hay algo debajo). Cada uno
## arrastra su extremo por encima del pozo para que caiga adentro. Luego bajan los extremos por el pozo.
static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var gate := "GateLeft" if d == 1 else "GateRight"
	return [["wait_floor"], ["rope", 60], ["walk_to", x.call(278), 3], ["wait", 0.4], ["rope", 120], ["wait", 0.6],
		["rope", 320], ["jump_to", x.call(400)], ["walk_to", x.call(600)], ["until", func(c): return c.level.get_node(gate).is_open, 5.0],
		["rope", 60], ["wait", 1.0], ["walk_to", x.call(690)], ["walk_to", x.call(ctx.var_f("stand", 634)), 3],
		["wait", 0.8], ["rope", ctx.var_f("r", 120)],
		["sync", "listos"], ["jiggle", x.call(ctx.var_f("stand", 634)), 8 * d, 10]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
