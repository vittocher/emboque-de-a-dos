extends RefCounted
const SCENE := "res://scenes/levels/tronco_2.tscn"
## Tronco 2: J1 (arriba) alarga la cuerda y J2 (abajo) la acorta hasta la misma
## altura bajo el muro (con el largo inicial, la campana queda tras el muro); un paso atrás y volver da el impulso para que se junten.
static func plan(ctx) -> Dictionary:
	return {
		"p1": [["wait_floor"], ["walk_to", 612], ["rope", ctx.var_f("r1", 305)], ["sync", "listos"],
			["walk_to", 540], ["walk_to", 612]],
		"p2": [["wait_floor"], ["walk_to", 668], ["rope", ctx.var_f("r2", 100)], ["sync", "listos"],
			["walk_to", 740], ["walk_to", 668]],
	}
