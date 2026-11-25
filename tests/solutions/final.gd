extends RefCounted
const SHORTCUTS := ["--no=throw --goal=418,578,1170,578", "--remove=LiftLeft,LiftRight --start=418,500,1170,500 --goal=579,328,1010,328", "--remove=Updraft --start=579,260,1010,260", "--start=579,260,1010,260 --goal=1010,328,579,328"]
const SCENE := "res://scenes/levels/final.tscn"
## Final, en tres actos. 1) Cada uno lanza al gancho de su lado, se columpia sobre el fuego y
## salta a su repisa (250 px más arriba). 2) Relevo: J1 se sube a su ascensor y J2 lo sube con su
## placa; arriba J1 pisa la suya y sube a J2. 3) Trapecio con viento: el gancho del medio solo
## se alcanza saltando dentro de una ráfaga. J1 se engancha y espera colgando; J2 toma la
## ráfaga siguiente y los extremos se embocan en el aire.
const M := preload("res://tests/solutions/moves.gd")
const V := preload("res://tests/solutions/viento_3.gd")

static func act1(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1600.0 - v
	var dir := "right" if d == 1 else "left"
	return [["wait_floor"], ["walk_to", x.call(ctx.var_f("tx", 84)), 3], ["wait", 0.5]] \
		+ M.throw_at(i, d, ctx.var_f("deg", 46)) \
		+ [["until", func(c): return c.hooked(i), 1.5], ["rope", ctx.var_f("len", 90), 2], ["pump", ctx.var_f("pump", 1.5)],
		["until", func(c): return c.p(i)._swing_omega * d < -0.3, 4.0],
		["until", func(c): return c.p(i)._swing_omega * d > 0.0 and (c.p(i).global_position.x - x.call(ctx.var_f("rx", 335))) * d > 0.0, 6.0],
		["tap", "jump"], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(405)) * d >= 0.0 or c.p(i).is_on_floor(), 3.0],
		["release", dir], ["wait_floor"], ["wait", 0.4], ["rope", 60, 1], ["wait", 0.4], ["walk_to", x.call(400) if d == 1 else 1200.0, 3], ["wait", 0.5]]

static func fly(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1600.0 - v
	var dir := "right" if d == 1 else "left"
	return [["rope", ctx.var_f("rf", 60), 2], ["walk_to", x.call(568) if d == 1 else 1012.0, 3]] + V.gust_starts("Updraft") + [["press", dir], ["until", func(c): return (c.p(i).global_position.x - (x.call(597) if d == 1 else 983.0)) * d > 0.0, 2.0], ["tap", "jump"],
		["until", func(c): return (c.p(i).global_position.x - x.call(ctx.var_f("fx", 740))) * d > 0.0 or c.hooked(i), 3.0], ["release", dir],
		["until", func(c): return c.hooked(i), 3.0]]

static func plan(ctx) -> Dictionary:
	return {
		"p1": act1(1, 1, ctx) + [["until", func(c): return c.level.get_node("LiftLeft").position.y > 618.0, 8.0], ["walk_to", 494, 4], ["wait", 0.5], ["sync", "j1_en_ascensor"],
			["until", func(c): return c.level.get_node("LiftLeft").position.y < 374.0, 12.0], ["walk_to", 553, 3], ["sync", "j1_arriba"], ["sync", "j2_en_ascensor"], ["walk_to", 592, 3], ["sync", "j2_arriba"]]
			+ fly(1, 1, ctx) + [["wait", 1.0], ["sync", "colgado"]],
		"p2": act1(2, -1, ctx) + [["sync", "j1_en_ascensor"], ["walk_to", 1142, 3], ["sync", "j1_arriba"], ["walk_to", 1200, 4], ["until", func(c): return c.level.get_node("LiftRight").position.y > 618.0, 8.0], ["walk_to", 1086, 4], ["wait", 0.5], ["sync", "j2_en_ascensor"],
			["until", func(c): return c.level.get_node("LiftRight").position.y < 374.0, 12.0], ["walk_to", 1020, 4], ["sync", "j2_arriba"], ["sync", "colgado"]]
			+ fly(2, -1, ctx),
	}
