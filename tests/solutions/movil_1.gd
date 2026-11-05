extends RefCounted
const SCENE := "res://scenes/levels/movil_1.tscn"
## Movil 1: la torre del encuentro mide 300 px. Cada uno espera a que su
## ascensor esté abajo, se sube, sube con él y se baja en su torre; los dos
## bajan el extremo al cuenco que cuelga entre las torres.
static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var lift := "ElevatorLeft" if d == 1 else "ElevatorRight"
	return [["wait_floor"], ["rope", 80], ["walk_to", x.call(280), 3],
		["until", func(c): return c.level.get_node(lift).position.y > 605.0, 10.0],
		["walk_to", x.call(370), 4],
		["until", func(c): return c.level.get_node(lift).position.y < 316.0, 10.0],
		["walk_to", x.call(ctx.var_f("stand", 596)), 3], ["wait", 0.5], ["rope", ctx.var_f("r", 200)],
		["sync", "listos"], ["jiggle", x.call(ctx.var_f("stand", 596)), 8 * d, 10]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
