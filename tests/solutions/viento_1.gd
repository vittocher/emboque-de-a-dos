extends RefCounted
const SCENE := "res://scenes/levels/viento_1.tscn"
## Viento 1: en el medio sube una corriente de aire, cerrada por dos cercos con
## una rendija abajo (pasa el emboque, no el jugador). Cada uno arrastra su
## extremo por la rendija, el viento lo levanta y suelta cuerda para que suba
## como un volantín hasta el embudo de arriba, donde se juntan.
static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	return [["wait_floor"], ["rope", 60], ["walk_to", x.call(470)], ["hold", "right" if d == 1 else "left", 1.2],
		["wait", 0.5], ["walk_to", x.call(518), 3],
		["wait", 0.5], ["rope", ctx.var_f("r", 310)], ["sync", "listos"],
		["until", func(c): return c.won(), ctx.var_f("hold", 8.0)], ["jiggle", x.call(518), 20 * d, 6]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
