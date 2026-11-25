extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--goal=930,268,670,268"]
const SCENE := "res://scenes/levels/peligro_1.tscn"
## Peligro 1: las púas matan al jugador, no al emboque. J1 sube en zigzag desde abajo; J2 baja
## desde arriba y vuelve a subir. Dos sopaipillas están entre las púas del fondo: las saca
## el extremo, colgando. En la meta los extremos cuelgan y basta con que uno se balancee.
const M := preload("res://tests/solutions/moves.gd")

static func fish(at: float, back: float, r: float) -> Array:
	return [["hang", at], ["rope", r], ["wait", 0.8], ["rope", 60], ["wait", 0.4], ["walk_to", back, 4]]

static func plan(ctx) -> Dictionary:
	var m: float = ctx.var_f("m", 50)
	var r: float = ctx.var_f("r", 120)
	return {
		"p1": [["wait_floor"], ["rope", 60]] + M.path(1, [[105, 260], [285, 430], ["over", 470, 500]]) + fish(602, 575, 250)
			+ M.path(1, [["over", 500, 470], [425, 280], [250, 125], [125, 255], [275, 455], [465, 645]])
			+ [["hang", 748], ["rope", r], ["wait", 0.8], ["sync", "listos"], ["swing", 748, m, 24]],
		"p2": [["wait_floor"], ["rope", 60]] + M.path(2, [[1495, 1392], ["go", 1510], ["go", 1372]])
			+ [["walk_to", 1365, 4], ["jump_to", 1308], ["wait_floor"]] + fish(1278, 1312, 285)
			+ M.path(2, [["go", 1165], [1140, 1045], [1045, 1155], [1155, 1045], [1020, 965]])
			+ [["hang", 852], ["rope", r], ["wait", 0.8], ["sync", "listos"], ["swing", 852, -m, 24]],
	}
