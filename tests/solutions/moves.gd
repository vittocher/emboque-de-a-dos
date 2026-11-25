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

## Salto simple: toma un impulso corto (así el extremo queda atrás y no se engancha bajo el
## borde), salta al pasar [param from] hacia [param to] y espera aterrizar.
static func hop(i: int, from: float, to: float) -> Array:
	var d := 1 if to > from else -1
	return [["walk_to", from - 25.0 * d, 4], ["wait", 0.2], ["press", _side(d)],
		["until", func(c): return (c.p(i).global_position.x - from) * d > 0.0, 1.0], ["leap_to", to], ["wait_floor"]]

## Salto con carrera: parte 70 px antes de [param from].
static func run_hop(i: int, from: float, to: float) -> Array:
	var d := 1 if to > from else -1
	return [["walk_to", from - 70.0 * d, 4], ["wait", 0.25], ["press", _side(d)],
		["until", func(c): return (c.p(i).global_position.x - from) * d > 0.0, 2.0], ["leap_to", to], ["wait_floor"]]

## Recorrido: lista de [desde, hasta] (salto), ["run", desde, hasta] (con carrera) o
## ["over", a, b] (salta con carrera por encima de un peligro que va de a hasta b) o
## ["go", x] (camina, aunque caiga por un borde).
static func path(i: int, list: Array) -> Array:
	var out := []
	for s: Array in list:
		if s[0] is String and s[0] == "run":
			out += run_hop(i, s[1], s[2])
		elif s[0] is String and s[0] == "over":
			var d := 1 if s[2] > s[1] else -1
			out += hop(i, s[1] - 60.0 * d, s[2] + 45.0 * d)
		elif s[0] is String and s[0] == "go":
			out += [["walk_to", s[1], 5], ["wait_floor"]]
		else:
			out += hop(i, s[0], s[1])
	return out
