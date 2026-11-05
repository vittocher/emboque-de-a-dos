extends RefCounted
const SCENE := "res://scenes/levels/viento_4.tscn"
## Viento 4 "Remonte": la torre del medio (290 px) no se alcanza saltando y el
## gancho está demasiado alto para el extremo. Cada uno cruza la corriente de su
## lado (al jugador no lo empuja), se para justo bajo el gancho y suelta cuerda:
## el viento sube el extremo derecho hacia arriba, hasta el gancho. Enganchado, tira de la
## cuerda (sube colgando), se balancea y salta al techo de la torre. Desde ahí,
## de a uno, recoge el extremo, se para sobre la ranura y lo baja al cuenco.
const M := preload("res://tests/solutions/moves.gd")

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var toward := "right" if d == 1 else "left"
	return [["wait_floor"], ["walk_to", x.call(260), 3], ["tap", "jump"], ["wait_floor"],
		["rope", 60, 1], ["walk_to", x.call(ctx.var_f("stand", 480)), 3], ["wait", 0.6], ["rope", 320],
		["until", func(c): return c.hooked(i), 4.0], ["rope", 60, 1],
		["until", func(c): return c.p(i).is_swing_taut(), 3.0], ["wait", 0.3],
		["release", toward], ["pump", ctx.var_f("pump", 1.2)],
		["until", func(c): return c.p(i)._swing_omega * d < -0.3, 4.0],
		["until", func(c): return c.p(i)._swing_omega * d > 0.0 and (c.p(i).global_position.x - x.call(ctx.var_f("rel", 490))) * d > 0.0, 6.0],
		["tap", "jump"], ["press", toward],
		["until", func(c): return (c.p(i).global_position.x - x.call(ctx.var_f("stop", 570))) * d >= 0.0 or c.p(i).is_on_floor(), 3.0],
		["release", toward], ["wait_floor"]]

## En el techo el extremo queda apoyado al lado de la ranura: se acorta, se pasa
## un poco más allá de la ranura (el extremo la cruza arrastrado y cae) y se
## vuelve encima de ella.
static func drop(i: int, back_dir: int, ctx) -> Array:
	return [["rope", 60, 1], ["wait", 0.6], ["walk_to", 640.0 - back_dir * 34.0, 3], ["wait", 0.4],
		["walk_to", 640.0, 2], ["wait", 0.6],
		["rope", ctx.var_f("r%d" % i, 180)], ["wait", 0.5], ["walk_to", 640.0 + back_dir * 18.0, 3]]

static func plan(ctx) -> Dictionary:
	return {
		"p1": side(1, 1, ctx) + [["sync", "arriba"]] + drop(1, -1, ctx) + [["sync", "uno"], ["wait", 1.0],
			["jiggle", 622.0, -8, 10]],
		"p2": side(2, -1, ctx) + [["sync", "arriba"], ["sync", "uno"]] + drop(2, 1, ctx) + [["jiggle", 658.0, 8, 10]],
	}
