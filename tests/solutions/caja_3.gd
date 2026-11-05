extends RefCounted
const SCENE := "res://scenes/levels/caja_3.tscn"
## Caja 3: J1 está en un pastito rodeado de caca y no tiene caja; su repisa mide
## 200. J2 empuja su caja desde la meseta, por su repisa y sobre el pozo, hasta
## tirarla por el borde izquierdo de la repisa de J1 (si la sigue, su extremo
## cae a la caca). La caja cae rodando hasta el pasto; J1, con la cuerda corta,
## la empuja contra la repisa (sin pisar la caca con su extremo), sube a la caja
## y a la repisa; los dos bajan el extremo por el pozo.
const C := preload("res://tests/solutions/caja_2.gd")

static func plan(ctx) -> Dictionary:
	var x := func(v: float) -> float: return v
	return {
		"p1": [["wait_floor"], ["until", func(c): return c.level.get_node("Box").global_position.y > 540.0 \
				and c.level.get_node("Box").linear_velocity.length() < 5.0, 30.0], ["wait", 0.5],
			["walk_to", 100, 3], ["wait", 0.3]] + C.push_until_stuck(1, 1) + C.climb_box(1, 1, x, 200, 255, 500)
			+ C.climb_box(1, 1, x, 262, 330, 470)
			+ [["walk_to", 628, 3], ["wait", 0.5], ["rope", ctx.var_f("r", 170)], ["sync", "listos"], ["jiggle", 628, 10, 10]],
		"p2": [["wait_floor"], ["press", "left"],
			["until", func(c): return c.level.get_node("Box").global_position.y > 380.0, 14.0], ["release", "left"],
			["wait", 1.0], ["walk_to", 660, 3], ["wait", 0.5], ["rope", ctx.var_f("r", 170)], ["sync", "listos"], ["jiggle", 660, -10, 10]],
	}
