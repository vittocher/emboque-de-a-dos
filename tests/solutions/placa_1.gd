extends RefCounted
const CONTROLS := ["12", "1", "2"]
const SHORTCUTS := ["--remove=ButtonForRight,ButtonForLeft --goal=530,568,750,568", "--remove=PlateGoalLeft --start=520,500,760,500", "--start=520,500,760,500 --goal=750,568,530,568"]
const SCENE := "res://scenes/levels/placa_1.tscn"
## Placa 1: cada compuerta se abre con el botón (en la repisa) del lado del OTRO jugador. Cada
## uno salta a su repisa y pisa su botón (queda trabado), cruza la compuerta que le abrió el
## compañero y cuelga su extremo en el hueco del medio. Ahí otra compuerta separa los extremos:
## solo se abre mientras los DOS pisan la placa de su borde; se balancean sin bajarse de ella.
static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var gate := "GateLeft" if d == 1 else "GateRight"
	return [["wait_floor"], ["rope", 100], ["walk_to", x.call(200)], ["wait", 0.3], ["jump_to", x.call(310)], ["wait_floor"], ["walk_to", x.call(320)], ["wait", 0.3],
		["until", func(c): return c.level.get_node(gate).is_open, 15.0], ["wait", 1.0],
		["walk_to", x.call(500)], ["rope", 60], ["hang", x.call(603)], ["rope", ctx.var_f("r", 150)],
		["wait", 0.8], ["sync", "listos"], ["swing", x.call(594), ctx.var_f("m", 45) * d, 24]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
