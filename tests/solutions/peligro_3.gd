extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--no=rope --goal=680,438,920,438", "--start=690,370,910,370 --goal=910,438,690,438"]
const SCENE := "res://scenes/levels/peligro_3.tscn"
## Peligro 3 "Brasas": J1 sube islas sobre el fuego; J2 baja por pasillos de techo bajo
## con brasas (matan a los dos), caca (al extremo) y púas (al jugador: el extremo pasa arrastrado).
## El extremo va detrás: hay que llevarlo corto. En la meta, los extremos cuelgan justo sobre
## el fuego: muy largos se queman; hay que balancearse los dos a la vez (S = 100).
const M := preload("res://tests/solutions/moves.gd")

static func plan(ctx) -> Dictionary:
	var m: float = ctx.var_f("m", 45)
	var r: float = ctx.var_f("r", 140)
	return {
		"p1": [["wait_floor"], ["rope", 60]] + M.path(1, [[115, 265], [308, 400], [372, 285], [245, 130], [160, 270]])
			+ M.path(1, [[300, 525], [540, 680]]) + [["hang", 743], ["rope", r], ["wait", 0.6], ["sync", "listos"], ["swing", 743, m, 24]],
		"p2": [["wait_floor"], ["rope", 60]] + M.path(2, [["over", 1485, 1450], ["over", 1325, 1285], ["go", 1165], ["over", 1230, 1290], ["over", 1430, 1465], ["go", 1540], ["run", 1480, 1290], ["over", 1215, 1170], ["over", 1025, 965]])
			+ [["hang", 857], ["rope", r], ["wait", 0.6], ["sync", "listos"], ["swing", 857, -m, 24]],
	}
