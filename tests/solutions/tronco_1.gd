extends RefCounted
const SCENE := "res://scenes/levels/tronco_1.tscn"
## Tronco 1: caminar hacia el muro; los extremos se juntan colgando bajo la repisa.
static func plan(ctx) -> Dictionary:
	return {
		"p1": [["wait_floor"], ["walk_to", 598]],
		"p2": [["wait_floor"], ["walk_to", 682]],
	}
