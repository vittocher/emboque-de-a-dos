extends PanelContainer
class_name ScoreHud

## Placa de puntaje del HUD (esquina superior derecha): sopaipilla + "Puntos: N"
## sobre madera, como los botones del menú. El ScoreManager del nivel le pone el
## texto (propiedad [member text], igual que a un Label) y llama [method bump]
## al juntar algo. Crece hacia la izquierda (anclada a la derecha).

@export var text: String = "":
	set(value):
		text = value
		if _label != null:
			_label.text = value

## Escala de la placa en el saltito al sumar puntos.
@export var bump_scale: float = 1.15
@export var bump_time: float = 0.3

@onready var _label: Label = $Margin/Row/Text

var _tween: Tween

func _ready() -> void:
	if not text.is_empty():
		_label.text = text

## Saltito de la placa al sumar puntos (la placa entera: a los hijos de un
## contenedor no se les puede cambiar la escala, el contenedor la reinicia).
## En tiempo real: con la cámara lenta del closeup se vería eterno.
func bump() -> void:
	if not is_node_ready():
		return
	if _tween != null:
		_tween.kill()
	pivot_offset = size * 0.5
	scale = Vector2.ONE * bump_scale
	_tween = create_tween().set_ignore_time_scale()
	_tween.tween_property(self, "scale", Vector2.ONE, bump_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
