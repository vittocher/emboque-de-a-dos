extends RefCounted
const SCENE := "res://scenes/levels/placa_1.tscn"
## Placa 1: cada compuerta se abre con el botón del lado del OTRO jugador. Cada
## uno pisa su botón (queda trabado), cruza la compuerta que le abrió el
## compañero y baja el extremo por el pozo del medio.
static func plan(ctx) -> Dictionary:
	return {
		"p1": [["wait_floor"], ["walk_to", 320], ["wait", 0.3], ["until", func(c): return c.level.get_node("GateLeft").is_open, 15.0],
			["wait", 1.0], ["walk_to", 628, 3], ["wait", 0.5], ["rope", ctx.var_f("r", 130)], ["sync", "listos"], ["jiggle", 628, 10, 10]],
		"p2": [["wait_floor"], ["walk_to", 960], ["wait", 0.3], ["until", func(c): return c.level.get_node("GateRight").is_open, 15.0],
			["wait", 1.0], ["walk_to", 652, 3], ["wait", 0.5], ["rope", ctx.var_f("r", 130)], ["sync", "listos"], ["jiggle", 652, -10, 10]],
	}
