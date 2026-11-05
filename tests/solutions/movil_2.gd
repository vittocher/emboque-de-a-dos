extends RefCounted
const SCENE := "res://scenes/levels/movil_2.tscn"
## Movil 2: un techo bajo impide saltar el foso; hay que cruzar en la plataforma
## que va y viene. Abajo hay caca: con la cuerda larga, el extremo que resbala
## de la plataforma cuelga hasta ella. Cada uno acorta la cuerda, se sube
## cuando la plataforma está en su lado, se baja en la isla y baja el extremo
## por el pozo del medio.
static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var mp := "PlatformLeft" if d == 1 else "PlatformRight"
	return [["wait_floor"], ["rope", ctx.var_f("short", 60)], ["walk_to", x.call(250), 3],
		["until", func(c): return absf(c.level.get_node(mp).position.x - x.call(330)) < 2.0, 10.0],
		["walk_to", x.call(330), 4],
		["until", func(c): return absf(c.level.get_node(mp).position.x - x.call(470)) < 2.0, 10.0],
		["walk_to", x.call(560), 4], ["walk_to", x.call(628), 3], ["wait", 0.5], ["rope", ctx.var_f("r", 110)],
		["sync", "listos"], ["jiggle", x.call(628), 8 * d, 10]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
