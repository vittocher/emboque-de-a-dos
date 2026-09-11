extends Node
class_name CloseupManager

## Efecto de celebración estilo Peggle: a medida que los dos extremos del emboque
## se acercan, la cámara hace un closeup hacia el punto medio y el juego entra en
## cámara lenta. Es continuo y reversible: si se alejan, vuelve a la vista normal.
## Reutilizable: instanciar en cada nivel y cablear cámara + los dos emboques.

@export var camera_path: NodePath
@export var emboque_a: NodePath
@export var emboque_b: NodePath

@export_group("Activación")
## Distancia (px) a la que empieza el efecto. Corto: solo cuando ya están cerca.
@export var activation_radius: float = 110.0
## Distancia (px) del closeup máximo (efecto al 100%).
@export var full_radius: float = 25.0

@export_group("Efecto")
## Multiplicador de zoom en el closeup máximo (>1 = más cerca).
@export var max_zoom: float = 2.0
## Escala de tiempo en el closeup máximo (1 = normal, menor = más lento).
@export var min_time_scale: float = 0.35
## Velocidad de la transición (suavizado). Usa tiempo real (no afectado por el slowdown).
@export var transition_speed: float = 6.0
## Tamaño del nivel (para no mostrar fuera de los bordes al hacer zoom).
@export var level_size: Vector2 = Vector2(1280, 720)

var _camera: Camera2D
var _a: Emboque
var _b: Emboque
var _home_pos: Vector2
var _home_zoom: Vector2
var _t: float = 0.0  # cercanía suavizada actual [0,1]

func _ready() -> void:
	_camera = get_node_or_null(camera_path) as Camera2D
	_a = get_node_or_null(emboque_a) as Emboque
	_b = get_node_or_null(emboque_b) as Emboque
	if _camera != null:
		_home_pos = _camera.global_position
		_home_zoom = _camera.zoom

func _process(delta: float) -> void:
	if _camera == null or _a == null or _b == null:
		return

	var pa := _a.get_end_position()
	var pb := _b.get_end_position()
	var dist := pa.distance_to(pb)
	var mid := (pa + pb) * 0.5

	# Cercanía objetivo según la distancia (0 lejos → 1 muy juntos).
	var target_t := clampf(inverse_lerp(activation_radius, full_radius, dist), 0.0, 1.0)

	# Suavizado con delta SIN escalar, para que la transición no se frene con el
	# propio slowdown (y el zoom-out al separarse siga siendo ágil).
	var unscaled := delta / maxf(Engine.time_scale, 0.0001)
	_t = lerpf(_t, target_t, clampf(transition_speed * unscaled, 0.0, 1.0))

	# Aplicar zoom, encuadre y cámara lenta.
	var zoom := _home_zoom.lerp(_home_zoom * max_zoom, _t)
	_camera.zoom = zoom
	_camera.global_position = _clamp_to_level(_home_pos.lerp(mid, _t), zoom)
	Engine.time_scale = lerpf(1.0, min_time_scale, _t)

## Mantiene el centro de cámara de modo que la vista (más chica con zoom) no
## se salga del nivel. Si la vista es más grande que el nivel, centra ese eje.
func _clamp_to_level(pos: Vector2, zoom: Vector2) -> Vector2:
	var view := get_viewport().get_visible_rect().size / zoom
	var half := view * 0.5
	var x := pos.x
	var y := pos.y
	if half.x * 2.0 >= level_size.x:
		x = level_size.x * 0.5
	else:
		x = clampf(x, half.x, level_size.x - half.x)
	if half.y * 2.0 >= level_size.y:
		y = level_size.y * 0.5
	else:
		y = clampf(y, half.y, level_size.y - half.y)
	return Vector2(x, y)

func _exit_tree() -> void:
	# CRÍTICO: Engine.time_scale es global; restaurarlo al salir de la escena.
	Engine.time_scale = 1.0
