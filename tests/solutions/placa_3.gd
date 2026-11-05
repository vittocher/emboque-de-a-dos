extends RefCounted
const SCENE := "res://scenes/levels/placa_3.tscn"
## Placa 3: cada compuerta se abre con una placa (no trabada) del lado del otro.
## J1 empuja su caja SOBRE la placa que abre a J2 (la caja queda pisándola).
## J2, sin caja, deja SU EXTREMO en la placa que abre a J1 (en un rebaje),
## cruza su compuerta con la cuerda larga; J1 cruza la suya; J2 recoge el
## extremo (su compuerta sigue abierta por la caja). Bajan los extremos al pozo.
static func plan(ctx) -> Dictionary:
	return {
		"p1": [["wait_floor"], ["walk_to", 130], ["press", "right"],
			["until", func(c): return c.level.get_node("Box").global_position.x >= ctx.var_f("bx", 322), 6.0],
			["release", "right"], ["wait", 0.5], ["jump_to", 420],
			["until", func(c): return c.level.get_node("GateLeft").is_open, 25.0], ["wait", 1.2],
			["walk_to", 600], ["sync", "dentro"], ["rope", 60], ["wait", 1.0], ["walk_to", 690], ["walk_to", 634, 3],
			["wait", 0.8], ["rope", 120], ["sync", "listos"], ["jiggle", 634, 8, 10]],
		"p2": [["wait_floor"], ["rope", 60], ["walk_to", 1002, 3], ["wait", 0.4], ["rope", 120], ["wait", 0.6],
			["rope", 320], ["jump_to", 880],
			["until", func(c): return c.level.get_node("GateRight").is_open, 20.0], ["wait", 1.2], ["walk_to", 690],
			["sync", "dentro"], ["rope", 60], ["wait", 1.5], ["walk_to", 590], ["walk_to", 646, 3],
			["wait", 0.8], ["rope", 120], ["sync", "listos"], ["jiggle", 646, -8, 10]],
	}
