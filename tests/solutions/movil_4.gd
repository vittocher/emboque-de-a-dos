extends RefCounted
const CONTROLS := ["12", "1", "2"]
const SCENE := "res://scenes/levels/movil_4.tscn"
## Movil 4 "Contratiempo": dos ascensores por lado que suben y bajan a
## contratiempo sobre el fuego. Con la cuerda corta (larga, el extremo cuelga al
## fuego cuando el ascensor está abajo), cada uno espera el de abajo, sube, se
## cambia al otro cuando están a la misma altura, sube y pasa a la plataforma del
## medio cuando está arriba. Las dos del medio van al revés (una sube y la otra
## baja): colgando los extremos hacia el muro y balanceándose los dos a la vez,
## se embocan al cruzarse.
static func lift_y(c, name: String) -> float:
	return c.level.get_node(name).position.y

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var a := "LiftLeftA" if d == 1 else "LiftRightA"
	var b := "LiftLeftB" if d == 1 else "LiftRightB"
	var g := "GoalLeft" if d == 1 else "GoalRight"
	var edge: float = x.call(585)
	return [["wait_floor"], ["walk_to", x.call(100), 3], ["tap", "jump"], ["wait_floor"], ["rope", ctx.var_f("short", 60), 1],
		["walk_to", x.call(ctx.var_f("wait_x", 160)), 3],
		["until", func(c): return lift_y(c, a) > 627.0, 12.0], ["walk_to", x.call(300), 3],
		["until", func(c): return lift_y(c, a) < 470.0, 6.0], ["tap", "jump"], ["wait_floor"],
		["until", func(c): return lift_y(c, a) < 401.0 and c.level.get_node(a)._wait > 0.45, 12.0],
		["walk_to", x.call(425), 3],
		["until", func(c): return lift_y(c, b) < 171.0 and c.level.get_node(b)._wait > 0.1 and lift_y(c, g) < 185.0, 60.0],
		["walk_to", edge, 3], ["wait", 0.5], ["rope", ctx.var_f("r", 180)], ["wait", 0.6], ["sync", "listos"],
		["swing", edge, 50 * d, 24]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
