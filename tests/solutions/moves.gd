extends RefCounted
## Movimientos reutilizables para los planes del bot (tests/play_level.gd).
## Cada función devuelve una lista de pasos para concatenar en un plan.
## i = 1 o 2 (jugador); dir = 1 (derecha) o -1 (izquierda).

static func _side(dir: int) -> String:
	return "right" if dir > 0 else "left"

## Corre hacia dir y salta al pasar jump_x.
static func run_jump(i: int, dir: int, jump_x: float) -> Array:
	return [["press", _side(dir)],
		["until", func(c): return (c.p(i).global_position.x - jump_x) * dir >= 0.0, 4.0],
		["tap", "jump"]]

## Tras saltar: espera engancharse, bombea [param pump] s, deja que vuelva y
## salta cuando va hacia dir pasando release_x; luego mantiene dir hasta stop_x
## y espera aterrizar.
static func swing_launch(i: int, dir: int, pump: float, release_x: float, stop_x: float) -> Array:
	return [["until", func(c): return c.hooked(i), 2.5],
		["release", _side(dir)], ["pump", pump],
		["until", func(c): return c.p(i)._swing_omega * dir < -0.3, 4.0],
		["until", func(c): return c.p(i)._swing_omega * dir > 0.0 and (c.p(i).global_position.x - release_x) * dir > 0.0, 6.0],
		["tap", "jump"], ["press", _side(dir)],
		["until", func(c): return (c.p(i).global_position.x - stop_x) * dir >= 0.0 or c.p(i).is_on_floor(), 3.0],
		["release", _side(dir)], ["wait_floor"]]

## Va y vuelve para balancear el extremo que cuelga (hasta ganar o [param times] veces).
static func nudge(i: int, home_x: float, back: float, times: int = 6) -> Array:
	return [["jiggle", home_x, back, times]]

## Lanzar (niveles con LevelRules.throw_enabled): acorta al mínimo, toma el
## extremo (tirar otra vez), empieza a apuntar y lo lanza cuando la mira pasa
## por [param deg] grados (subiendo). El jugador mira hacia dir.
static func throw_at(i: int, dir: int, deg: float) -> Array:
	return [["rope", 60, 1], ["wait", 0.2], ["tap", "pull"],
		["until", func(c): return c.e(i)._throw_state == 1, 1.0],
		["tap", "right" if dir > 0 else "left"], ["wait", 0.1], ["tap", "throw"],
		["until", func(c): return c.e(i)._throw_state == 2, 1.0],
		["until", func(c):
			var a: float = pingpong(c.e(i)._aim_time * c.e(i).aim_sweep_speed_deg, c.e(i).aim_max_angle_deg)
			return a >= deg - 0.5, 3.0],
		["tap", "throw"]]
