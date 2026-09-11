extends Node2D
class_name WinManager

## Condición de victoria: que el PALITO entre en la CAMPANA. Un magnetismo de
## distancia + ángulo asiste el emboque cuando están cerca y ~alineados, para
## que ganar sea satisfactorio sin ser frustrante. Los extremos colisionan por
## física real; el magnetismo solo empuja/gira, no teletransporta.

@export var emboque_a: NodePath
@export var emboque_b: NodePath

@export_group("Magnetismo")
## Radio (punta del palito ↔ boca de la campana) en que empieza la asistencia.
@export var magnet_radius: float = 70.0
## Aceleración de atracción cuando están casi tocándose (px/s^2). Más bajo = más sutil.
@export var linear_accel: float = 900.0
## Ganancia de alineación angular (rad/s por rad de error, escalada por cercanía).
@export var angular_gain: float = 2.5

@export_group("Victoria")
## Distancia punta↔cavidad para ganar por proximidad+ángulo (respaldo).
@export var capture_distance: float = 12.0
## Error angular máximo (rad) para el respaldo de proximidad.
@export var capture_angle: float = 0.45
## Tiempo que debe cumplirse la condición para ganar (s).
@export var capture_time: float = 0.2
@export var win_label: NodePath
@export var restart_delay: float = 2.5

var _palito: Emboque
var _campana: Emboque
var _label: CanvasItem
var _hold: float = 0.0
var _won: bool = false

func _ready() -> void:
	var a := get_node_or_null(emboque_a) as Emboque
	var b := get_node_or_null(emboque_b) as Emboque
	# Identificar cuál es cuál por su end_kind.
	if a != null and a.end_kind == "campana":
		_campana = a
		_palito = b
	else:
		_campana = b
		_palito = a
	_label = get_node_or_null(win_label) as CanvasItem
	if _label != null:
		_label.visible = false

func _physics_process(delta: float) -> void:
	if _won or _palito == null or _campana == null:
		return
	var pal := _palito.get_end()
	var camp := _campana.get_end()
	if pal == null or camp == null:
		return

	# Geometría en mundo.
	var tip: Vector2 = pal.get_node("Tip").global_position
	var mouth: Vector2 = camp.get_node("Mouth").global_position
	var cavity: Vector2 = camp.get_node("Cavity").global_position
	var pal_axis := pal.global_transform.x.normalized()          # base → punta
	var camp_open := camp.global_transform.x.normalized()         # cavidad → boca (hacia afuera)

	var dist := tip.distance_to(mouth)

	if dist < magnet_radius:
		var closeness: float = clampf(1.0 - dist / magnet_radius, 0.0, 1.0)

		# Magnetismo lineal: la punta hacia la cavidad; la campana hacia la punta.
		var to_cavity := cavity - tip
		if to_cavity.length() > 0.001:
			var d := to_cavity.normalized()
			pal.apply_central_force(d * linear_accel * closeness * pal.mass)
			camp.apply_central_force(-d * linear_accel * 0.6 * closeness * camp.mass)

		# Magnetismo angular: el palito apunta HACIA la cavidad (eje = -camp_open);
		# la campana abre su boca hacia la punta.
		var desired_pal := -camp_open
		var desired_camp := (tip - cavity).normalized() if (tip - cavity).length() > 0.001 else camp_open
		pal.angular_velocity = pal_axis.angle_to(desired_pal) * angular_gain * closeness
		camp.angular_velocity = camp_open.angle_to(desired_camp) * angular_gain * closeness

	# Victoria: palito dentro de la cavidad (real), o respaldo por proximidad+ángulo.
	if _is_embocado(pal, camp, tip, cavity, pal_axis, camp_open):
		_hold += delta
		if _hold >= capture_time:
			_win()
	else:
		_hold = 0.0

func _is_embocado(pal: RopeEnd, camp: RopeEnd, tip: Vector2, cavity: Vector2, pal_axis: Vector2, camp_open: Vector2) -> bool:
	# Real: la punta del palito está dentro del sensor de cavidad de la campana.
	var cavity_sensor := _campana.get_cavity_sensor()
	if cavity_sensor != null and cavity_sensor.overlaps_body(pal):
		return true
	# Respaldo: muy cerca y bien alineado (magnetismo asegura que sea alcanzable).
	var aligned: bool = absf(pal_axis.angle_to(-camp_open)) < capture_angle
	return tip.distance_to(cavity) < capture_distance and aligned

func _win() -> void:
	if _won:
		return
	_won = true
	if _label != null:
		_label.visible = true
	# ignore_time_scale=true: si hay slow-mo del closeup al ganar, la recarga
	# ocurre igual tras restart_delay reales (no se alarga por la cámara lenta).
	await get_tree().create_timer(restart_delay, true, false, true).timeout
	get_tree().reload_current_scene()
