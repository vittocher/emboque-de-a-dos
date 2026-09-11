extends Area2D
class_name PlayerDeathZone

## Zona de muerte para el JUGADOR: cuando un jugador la toca, reinicia el nivel.
## Es un script separado del de emboque a propósito, para poder darles mecánicas
## distintas en el futuro (aunque hoy hagan casi lo mismo).

## Se emite justo antes de recargar (útil para tests y para futuros efectos).
signal triggered(body: Node)

## Si es false, solo emite la señal y NO recarga (para tests). En juego: true.
@export var reload_on_death: bool = true

var _fired: bool = false

func _ready() -> void:
	collision_mask = 2  # capa 2 = jugadores
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _fired:
		return
	_fired = true
	triggered.emit(body)
	if reload_on_death:
		get_tree().reload_current_scene()
