extends RefCounted
const SCENE := "res://scenes/level_4.tscn"
## Nivel 4 del equipo ("Escalones"): la caja empieza DEBAJO de la primera
## plataforma (200 px sobre el piso). Cada uno salta por encima de la caja, la
## empuja hacia atrás hasta que quede fuera de la plataforma, se sube a ella,
## salta a la primera plataforma y sube los escalones (100 px) hasta la meta del
## centro, donde se juntan los extremos.
const C := preload("res://tests/solutions/caja_2.gd")

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var back := "left" if d == 1 else "right"
	var box := "Box1" if d == 1 else "Box2"
	return [["wait_floor"], ["rope", 100], ["walk_to", x.call(170)], ["jump_to", x.call(330)], ["wait", 0.3],
		["press", back], ["until", func(c): return (c.level.get_node(box).global_position.x - x.call(ctx.var_f("bx", 150))) * d <= 0.0, 6.0],
		["release", back], ["wait", 0.4]] \
		+ C.climb_box(i, -d, x, 230, 190, 470) + [["rope", 80], ["wait", 0.4]] \
		+ C.climb_box(i, d, x, 150, 230, 330) \
		+ C.climb_box(i, d, x, 330, 420, 230) \
		+ C.climb_box(i, d, x, 505, 568, 130) \
		+ [["wait", 0.3]]

## En la meta: cada uno se para sobre la ranura del medio, acorta la cuerda al
## mínimo (el extremo, que venía arrastrándose detrás, cae por la ranura) y la
## alarga hasta el cuenco. De a uno, para que no se traben en la ranura.
static func drop(i: int, d: int, ctx) -> Array:
	return [["walk_to", 640.0, 2], ["rope", 60, 1], ["wait", 0.6], ["rope", ctx.var_f("r%d" % i, 160)],
		["wait", 0.5], ["walk_to", 640.0 - d * ctx.var_f("back", 30), 3]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx) + [["sync", "arriba"]] + drop(1, 1, ctx) + [["sync", "uno"], ["wait", 1.0],
			["jiggle", 610.0, -10, 10]],
		"p2": side(2, -1, ctx) + [["sync", "arriba"], ["sync", "uno"]] + drop(2, -1, ctx) + [["jiggle", 670.0, 10, 10]]}
