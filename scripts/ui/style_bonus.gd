extends VBoxContainer
class_name StyleBonus

## Bonos de estilo al embocar ("¡Limpio!", "¡Al vuelo!"): un texto por bono bajo el
## cartel de victoria, que aparece con un salto. Solo se muestran (no dan puntos). Los
## decide WinManager.style_bonuses().

@export var label_settings: LabelSettings
## Segundos entre el emboque y el primer bono, y entre uno y otro.
@export var delay: float = 0.35
@export var pop_time: float = 0.25

func show_bonuses(keys: Array[String]) -> void:
	for i in keys.size():
		var label := Label.new()
		label.text = keys[i]
		label.label_settings = label_settings
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.modulate.a = 0.0
		add_child(label)
		_pop(label, delay * (i + 1))

## En tiempo real: al embocar puede seguir la cámara lenta.
func _pop(label: Label, wait: float) -> void:
	var tween := create_tween().set_ignore_time_scale(true)
	tween.tween_interval(wait)
	tween.tween_callback(func() -> void:
		label.pivot_offset = label.size * 0.5
		label.scale = Vector2.ONE * 1.8)
	tween.tween_property(label, "modulate:a", 1.0, pop_time * 0.5)
	tween.parallel().tween_property(label, "scale", Vector2.ONE, pop_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
