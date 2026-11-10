extends RefCounted
const SCENE := "res://scenes/levels/movil_4.tscn"
## Movil 4 "Contratiempo": dos ascensores por lado que suben y bajan a
## contratiempo sobre el fuego. Con la cuerda corta (larga, el extremo cuelga al
## fuego cuando el ascensor está abajo), cada uno espera el de abajo, sube, se
## cambia al otro cuando están a la misma altura y sube hasta el techo de la
## torre. De a uno, baja el extremo por la ranura al cuenco.
static func lift_y(c, name: String) -> float:
	return c.level.get_node(name).position.y

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var a := "LiftLeftA" if d == 1 else "LiftRightA"
	var b := "LiftLeftB" if d == 1 else "LiftRightB"
	return [["wait_floor"], ["walk_to", x.call(100), 3], ["tap", "jump"], ["wait_floor"], ["rope", ctx.var_f("short", 60), 1],
		["walk_to", x.call(ctx.var_f("wait_x", 160)), 3],
		["until", func(c): return lift_y(c, a) > 627.0, 12.0], ["walk_to", x.call(300), 3],
		["until", func(c): return lift_y(c, a) < 470.0, 6.0], ["tap", "jump"], ["wait_floor"],
		["until", func(c): return lift_y(c, a) < 401.0 and c.level.get_node(a)._wait > 0.45, 12.0],
		["walk_to", x.call(425), 3],
		["until", func(c): return lift_y(c, b) < 171.0 and c.level.get_node(b)._wait > 0.3, 8.0],
		["walk_to", x.call(560), 3], ["wait", 0.3]]

## Igual que en Escalones: acortar, pasar sobre la ranura y soltar cuerda.
static func drop(i: int, back_dir: int, ctx) -> Array:
	return [["rope", 60, 1], ["wait", 1.0], ["walk_to", 640.0 - back_dir * 34.0, 3], ["wait", 0.6],
		["walk_to", 640.0, 2], ["wait", 1.2], ["rope", ctx.var_f("r%d" % i, 170)], ["wait", 0.8],
		["walk_to", 640.0 + back_dir * 18.0, 3]]

static func plan(ctx) -> Dictionary:
	return {
		"p1": side(1, 1, ctx) + [["sync", "arriba"]] + drop(1, -1, ctx) + [["sync", "uno"], ["wait", 1.0],
			["jiggle", 622.0, -8, 10]],
		"p2": side(2, -1, ctx) + [["sync", "arriba"], ["sync", "uno"]] + drop(2, 1, ctx) + [["jiggle", 658.0, 8, 10]],
	}
