extends Area2D
class_name EmboqueDeathZone

## Zona de muerte para el EMBOQUE: cuando un extremo (palito o campana) la toca,
## reinicia el nivel. Script separado del de jugador para poder darles mecánicas
## distintas en el futuro.

## Se emite justo antes de recargar (útil para tests y para futuros efectos).
signal triggered(body: Node)

## Si es false, solo emite la señal y NO recarga (para tests). En juego: true.
@export var reload_on_death: bool = true

var _fired: bool = false

func _ready() -> void:
	collision_mask = 12  # capas 3+4 = campana (4) + palito (8)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _fired:
		return
	_fired = true
	triggered.emit(body)
	if reload_on_death:
		get_tree().reload_current_scene()
