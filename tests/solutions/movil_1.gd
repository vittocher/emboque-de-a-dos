extends RefCounted
const CONTROLS := ["12", "1", "2"]
const SHORTCUTS := ["--remove=ElevatorLeft,ElevatorRight --goal=510,268,770,268", "--start=510,200,770,200 --goal=770,268,510,268"]
const SCENE := "res://scenes/levels/movil_1.tscn"
## Movil 1: la torre del encuentro mide 300 px. Cada uno espera a que su
## ascensor esté abajo, se sube, sube con él y se baja en su torre; los
## extremos cuelgan entre las torres y basta con que uno se balancee.
static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var lift := "ElevatorLeft" if d == 1 else "ElevatorRight"
	return [["wait_floor"], ["rope", 80], ["walk_to", x.call(280), 3],
		["until", func(c): return c.level.get_node(lift).position.y > 605.0, 10.0],
		["walk_to", x.call(379), 4],
		["until", func(c): return c.level.get_node(lift).position.y < 316.0, 10.0],
		["walk_to", x.call(500), 3], ["rope", 60], ["hang", x.call(594)], ["rope", ctx.var_f("r", 170)], ["wait", 0.8],
		["sync", "listos"], ["swing", x.call(594), ctx.var_f("m", 50) * d, 24]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
