extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--goal=690,458,590,258"]
const SCENE := "res://scenes/levels/tronco_2.tscn"
## Tronco 2: J1 sube por la izquierda; J2 baja en zigzag por la derecha, pasa por debajo del muro
## corto y sube. Sus repisas están a distinta altura: J1 (arriba) alarga la cuerda y J2 (abajo) la
## acorta hasta que los extremos cuelgan a la misma altura bajo el muro (con el largo inicial, la
## campana queda tras él); un paso atrás y volver da el impulso para que se junten.
const M := preload("res://tests/solutions/moves.gd")

static func plan(ctx) -> Dictionary:
	return {
		"p1": [["wait_floor"]] + M.path(1, [[225, 300], [265, 150], [180, 345], [370, 450], [470, 585]]) + [["rope", 60, 2], ["hang", 527.0], ["rope", ctx.var_f("r1", 305)], ["sync", "listos"], ["wait", 0.8],
			["swing", 612, 60, 8]],
		"p2": [["wait_floor"]] + M.path(2, [["go", 1050], ["go", 1205], ["go", 1050], ["go", 890], [880, 805], [790, 690]]) + [["rope", 60, 2], ["hang", 753.0], ["rope", ctx.var_f("r2", 100)], ["sync", "listos"], ["wait", 0.8],
			["swing", 668, -60, 8]],
	}
