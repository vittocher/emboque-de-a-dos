extends RefCounted
const CONTROLS := ["12", "1", "2"]
const SHORTCUTS := ["--no=box --goal=740,133,1100,133", "--remove=BoxA,BoxB --goal=20,20,740,648", "--remove=BoxLeft3,BoxRight3 --start=780,65,1150,65"]
const SCENE := "res://scenes/levels/caja_2.tscn"
## Caja 2 "La mudanza": J1 tiene tres cajas y J2 ninguna. Por el pozo de la izquierda
## solo pasan las cajas (el fuego mata a los jugadores y a los extremos). J1 le bota dos a
## J2: con la primera, J2 TAPA el foso; la segunda (grande) la pasa por encima y la usa de escalón
## para su pared. J1 se guarda la tercera para subir a su torre (si bota de más, J2 la empuja
## al hoyo de la izquierda y vuelve a su lugar, arriba). Arriba el hueco es demasiado ancho:
## cada uno empuja la caja que hay ahí hasta que ASOME por el borde (si se pasa, cae y
## reaparece), se para en ella y se balancean los dos a la vez.
const M := preload("res://tests/solutions/moves.gd")
const ML := 845.0
const QL := ML + 215.0

static func climb_box(i: int, d: int, x: Callable, stand: float, land: float, top_y: float) -> Array:
	var dir := "right" if d == 1 else "left"
	return [["walk_to", x.call(stand)], ["wait", 0.4], ["tap", "jump"],
		["until", func(c): return c.p(i).global_position.y < top_y, 1.0], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(land)) * d > 0.0, 1.5], ["release", dir],
		["wait_floor"]]

static func push_until_stuck(i: int, d: int) -> Array:
	var dir := "right" if d == 1 else "left"
	return [["press", dir], ["wait", 0.3],
		["until", func(c): return absf(c.p(i).get_real_velocity().x) < 5.0, 6.0], ["release", dir], ["wait", 0.3]]

## Arriba: asoma la caja por el borde, se para en ella y se balancea.
static func overhang(i: int, d: int, ctx) -> Array:
	var edge_of_floor: float = ML if d == 1 else QL
	var dir := "right" if d == 1 else "left"
	var box := "BoxLeft3" if d == 1 else "BoxRight3"
	var ov: float = ctx.var_f("ov", 36)  # cuánto asoma la caja por el borde
	var bx: float = edge_of_floor + (ov - 32.0) * d
	var edge: float = edge_of_floor + (ov + ctx.var_f("e", 15)) * d
	return [["wait", 0.5], ["press", dir],
		["until", func(c): return (c.level.get_node(box).position.x - bx) * d >= -8.0, 6.0], ["release", dir], ["wait", 0.4],
		["walk_to", edge_of_floor - 92.0 * d, 4], ["wait", 0.3], ["tap", "jump"],
		["until", func(c): return c.p(i).global_position.y < 75.0, 1.0], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - (bx - 30.0 * d)) * d > 0.0, 1.5], ["release", dir], ["wait_floor"],
		["sync", "arriba"], ["hang", edge], ["rope", ctx.var_f("r", 160)], ["wait", 0.5],
		["sync", "listos"], ["swing", edge, ctx.var_f("m", 45) * d, 24]]

static func plan(ctx) -> Dictionary:
	var n := func(v: float) -> float: return v
	var drop := func(box: String) -> Array:
		return [["press", "left"], ["until", func(c): return c.level.get_node(box).position.y > 455.0, 6.0], ["release", "left"], ["wait", 0.3]]
	return {
		"p1": [["wait_floor"], ["rope", 60], ["wait", 0.3]] + climb_box(1, -1, n, 658, 600, 215) + [["walk_to", 515, 3], ["wait_floor"]] + climb_box(1, -1, n, 508, 450, 215) + [["walk_to", 366, 3], ["wait_floor"],
			["sync", "bota1"]] + drop.call("BoxA")
			+ [["sync", "bota2"], ["walk_to", 330, 3]] + climb_box(1, 1, n, 372, 430, 215) + [["walk_to", 515, 3], ["wait_floor"]] + drop.call("BoxB")
			+ [["walk_to", 480, 4]] + push_until_stuck(1, 1) + climb_box(1, 1, n, 586, 640, 215)
			+ climb_box(1, 1, n, 674, 715, 133) + [["rope", 170]] + overhang(1, 1, ctx),
		"p2": [["wait_floor"], ["rope", 80], ["walk_to", 110, 3], ["sync", "bota1"],
			["until", func(c): return c.level.get_node("BoxA").position.y > 785.0, 8.0], ["wait", 0.5], ["press", "right"],
			["until", func(c): return c.level.get_node("BoxA").position.y > 855.0, 8.0], ["release", "right"], ["walk_to", 110, 3], ["sync", "bota2"],
			["until", func(c): return c.level.get_node("BoxB").position.y > 775.0, 16.0], ["wait", 0.5], ["rope", 60]]
			+ push_until_stuck(2, 1) + climb_box(2, 1, n, 586, 640, 725) + climb_box(2, 1, n, 674, 725, 648)
			+ M.path(2, [["go", 1300], [1415, 1520], [1495, 1400], [1415, 1520], [1495, 1400], [1415, 1520], [1495, 1400], [1335, QL + 160.0]])
			+ [["walk_to", QL + 120.0, 4], ["rope", 60]] + overhang(2, -1, ctx),
	}
