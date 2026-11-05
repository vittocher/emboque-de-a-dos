extends TextureRect
class_name LocalizedTextureRect

## TextureRect para imágenes con TEXTO DIBUJADO (portada, menú de pausa): muestra
## la versión del idioma actual si existe (misma imagen en una subcarpeta con el
## código del idioma, p. ej. assets/ui/en/portada.png; ver Languages) y se
## actualiza sola al cambiar de idioma. En el editor se pone la imagen original.

var _original: Texture2D

func _ready() -> void:
	_original = texture
	_apply()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _original != null:
		_apply()

func _apply() -> void:
	texture = Languages.localized_texture(_original)
