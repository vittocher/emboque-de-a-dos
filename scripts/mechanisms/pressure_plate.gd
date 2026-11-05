@tool
extends Node2D
class_name PressurePlate

## Placa de presión: se hunde mientras tenga algo encima (un jugador, un extremo
## del emboque o una caja) y activa su canal (ver Channel): abre compuertas y
## mueve plataformas del mismo color. Con [member latch] queda trabada apenas se
## presiona (un botón que se aprieta una vez).
## Se apoya en el piso: la posición del nodo es el centro de su base, sobre la
## superficie. Arte: assets/props/placa/ (base + tapa, la tapa se tiñe del color
## del canal).

signal changed(is_pressed: bool)

@export var channel := 0:
	set(value):
		channel = value
		_paint()
## Queda presionada para siempre una vez activada.
@export var latch := false

var pressed := false
var _count := 0

@onready var _top: Node2D = $Top
@onready var _sensor: Area2D = $Sensor

func _enter_tree() -> void:
	add_to_group(Channel.PLATES)

func _ready() -> void:
	_paint()
	if Engine.is_editor_hint():
		return
	_sensor.body_entered.connect(func(_b: Node) -> void: _count += 1; _update())
	_sensor.body_exited.connect(func(_b: Node) -> void: _count = maxi(_count - 1, 0); _update())

func _paint() -> void:
	var top := get_node_or_null("Top/Sprite") as CanvasItem
	if top != null:
		top.modulate = Channel.color(channel)

func _update() -> void:
	var now := _count > 0 or (latch and pressed)
	if now == pressed:
		return
	pressed = now
	var tween := create_tween()
	tween.tween_property(_top, "position:y", 4.0 if pressed else 0.0, 0.08)
	Sfx.play(&"plate", 1.0 if pressed else 1.25)
	changed.emit(pressed)
	Channel.notify(get_tree(), channel)
