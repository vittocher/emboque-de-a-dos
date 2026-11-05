extends RefCounted
const SCENE := "res://scenes/levels/peligro_1.tscn"
## Peligro 1: las púas matan al jugador, no al emboque. Cada uno salta su zanja
## de púas, se para en el borde y baja el extremo a la zanja (sin morir) por la
## sopaipilla; lo sube, va al borde de su bloque y apoya el extremo en el
## cuenco, donde se juntan.
const M := preload("res://tests/solutions/moves.gd")

static func side(i: int, d: int, r: float) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var dir := "right" if d == 1 else "left"
	return [["wait_floor"], ["rope", 140], ["walk_to", x.call(190)], ["wait", 0.3], ["press", dir], ["tap", "jump"],
		["until", func(c): return c.p(i).is_on_floor() and absf(c.p(i).global_position.x - x.call(250)) > 50.0, 2.0],
		["release", dir], ["walk_to", x.call(263), 3], ["wait", 0.5], ["rope", 150], ["wait", 1.0],
		["rope", 60], ["wait", 0.5],
		["walk_to", x.call(576)], ["rope", r], ["sync", "listos"]] + M.nudge(i, x.call(576), 25 * d, 10)

static func plan(ctx) -> Dictionary:
	var r: float = ctx.var_f("r", 180)
	return {"p1": side(1, 1, r), "p2": side(2, -1, r)}
