extends RefCounted
const CONTROLS := ["12", "1", "2"]
const SHORTCUTS := ["--no=box --goal=540,68,740,68", "--start=535,0,745,0 --goal=745,68,535,68"]
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
		+ C.climb_box(i, d, x, 325, 410, 230)

## Del segundo escalón a la meta.
static func last_step(i: int, d: int) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	return C.climb_box(i, d, x, 455, 520, 100) + [["wait", 0.3]]

## En la meta los extremos cuelgan por el hueco, con la cortina entre los jugadores.
static func goal(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	return [["rope", 60], ["hang", x.call(593)], ["rope", ctx.var_f("r", 150)], ["wait", 0.8], ["sync", "listos"],
		["swing", x.call(593), ctx.var_f("m", 45) * d, 24]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx) + last_step(1, 1) + goal(1, 1, ctx),
		"p2": side(2, -1, ctx) + last_step(2, -1) + goal(2, -1, ctx)}
