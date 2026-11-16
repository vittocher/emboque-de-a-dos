extends ColorRect
class_name WoodPlaque

## Fondo de madera del HUD: un ColorRect con el shader de los botones del menú
## (shaders/madera_boton.gdshader: veta, esquinas redondeadas y borde dorado).
## Mantiene el tamaño del shader al día con el del rect y prende el brillo con
## [member active]. El material de cada instancia tiene que ser propio
## (resource_local_to_scene), o todas las placas compartirían el tamaño.

## Resaltada: borde dorado más grueso y brillo interior (mouse encima).
@export var active: bool = false:
	set(value):
		active = value
		_set_param("active", 1.0 if value else 0.0)

func _ready() -> void:
	resized.connect(_sync_size)
	_sync_size()
	_set_param("active", 1.0 if active else 0.0)

func _sync_size() -> void:
	_set_param("rect_size", size)

func _set_param(param: StringName, value: Variant) -> void:
	var mat := material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter(param, value)
