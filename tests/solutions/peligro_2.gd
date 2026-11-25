extends RefCounted
const CONTROLS := ["12", "1", "2"]
const SHORTCUTS := ["--no=rope"]
const SCENE := "res://scenes/levels/peligro_2.tscn"
## Peligro 2 "El alambre": la caca mata al emboque. Los jugadores caminan por el techo de
## un pasillo y los extremos van POR ADENTRO (la cuerda atraviesa la madera; el extremo, no).
## Para pasar bajo un diente hay que alargar; para pasar sobre la caca que está pegada a
## él, acortar (no hay espacio para esquivarla balanceándose, ni para saltar: arriba el
## techo es bajo). Los escalones de arriba piden cuerda larga: con el extremo pegado a la
## madera no se puede saltar. J1: diente, caca, escalón, diente, caca. J2: escalón, caca,
## diente, caca. En el medio juntan los extremos bajo la columna que los separa.
static func plan(ctx) -> Dictionary:
	var deep: float = ctx.var_f("deep", 285)
	var short: float = ctx.var_f("short", 125)
	var w: float = ctx.var_f("w", 0.9)
	var m: float = ctx.var_f("m", 70)
	var r: float = ctx.var_f("r", 140)
	var x := func(v: float) -> float: return 1600.0 - v
	# Avanza en dos pasos iguales separados por medio período del péndulo (el segundo
	# frena el balanceo que dejó el primero) y, quieto, cambia el largo de la cuerda.
	var go := func(a: float, b: float, now: float, rope: float) -> Array:
		return [["walk_to", (a + b) * 0.5, 2], ["wait", PI * sqrt(now / 980.0) - ctx.var_f("walk", 0.15)], ["walk_to", b, 2], ["wait", w], ["rope", rope], ["wait", w]]
	return {
		"p1": [["wait_floor"], ["wait", 0.5]] + go.call(70.0, 90.0, 170.0, deep) + go.call(90.0, 237.0, deep, short) + go.call(237.0, 385.0, short, 310.0)
			+ [["jump_to", 452], ["wait_floor"], ["walk_to", 452, 4], ["wait", 1.5], ["walk_to", 512, 4], ["wait_floor"], ["wait", w]]
			+ go.call(512.0, 590.0, 310.0, short) + go.call(590.0, 749.0, short, r) + [["sync", "listos"], ["swing", 749, m, 20]],
		"p2": [["wait_floor"], ["wait", 0.5]] + go.call(x.call(60), x.call(80), 170.0, 310.0) + [["jump_to", x.call(155)], ["wait_floor"], ["walk_to", x.call(150), 4], ["rope", 190], ["wait", 1.5], ["walk_to", x.call(200), 2], ["wait", 1.5], ["press", "left"], ["until", func(c): return not c.on_floor(2), 1.0], ["release", "left"], ["rope", short], ["wait_floor"]]
			+ go.call(x.call(217), x.call(217), short, short) + go.call(x.call(217), x.call(395), short, deep) + go.call(x.call(395), x.call(529), deep, short)
			+ go.call(x.call(529), x.call(749), short, r) + [["sync", "listos"], ["swing", x.call(749), -m, 20]],
	}
