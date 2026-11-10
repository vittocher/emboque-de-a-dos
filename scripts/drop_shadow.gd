@tool
extends Node2D
class_name DropShadow

## Sombra difusa de un sprite (o de una cuerda) sobre el fondo: hace que jugadores,
## emboques, cajas y demás objetos se despeguen de la pared del fondo.
## Uso: agregarlo como HIJO del Sprite2D / AnimatedSprite2D / Line2D que proyecta la
## sombra. Copia su dibujo cada cuadro (animación, flip, puntos de la cuerda) y lo
## pinta oscuro y difuminado en la capa de sombras (VisualFx.Z_SHADOW), corrido
## [member shadow_offset] px del mundo hacia abajo a la derecha. Hereda la
## transformación, visibilidad y modulate de su padre (si el sprite se oculta o se
## desvanece, la sombra también).

## Corrimiento de la sombra en px del mundo (independiente de la rotación del objeto).
@export var shadow_offset := VisualFx.LIGHT_OFFSET
## Difuminado (px del mundo).
@export var blur := 4.0
## Color; el alfa es la opacidad máxima.
@export var color := Color(0.0, 0.0, 0.0, 0.55)
## Engorda la sombra (0..1): sirve para dibujos delgados (los jugadores), cuya
## sombra corrida quedaría casi toda escondida detrás de ellos.
@export_range(0.0, 1.0) var grow := 0.0

var _src: CanvasItem
var _copy: CanvasItem

func _ready() -> void:
	_src = get_parent() as CanvasItem
	if _src is Sprite2D or _src is AnimatedSprite2D:
		var sprite := Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.material = VisualFx.silhouette_material({"tint": color, "blur_px": blur, "grow": grow})
		_copy = sprite
	elif _src is Line2D:
		var line := Line2D.new()
		var src_line := _src as Line2D
		line.width = src_line.width + blur
		line.default_color = color
		line.texture = _soft_band()
		line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		_copy = line
	else:
		set_process(false)
		return
	_copy.name = "Shadow"
	_copy.z_index = VisualFx.Z_SHADOW
	_copy.z_as_relative = false
	add_child(_copy)
	_sync()

func _process(_delta: float) -> void:
	_sync()

func _sync() -> void:
	if _src == null or _copy == null or not _src.is_visible_in_tree():
		return
	# Corrimiento constante en el mundo aunque el objeto gire o esté escalado.
	(_copy as Node2D).position = get_global_transform().affine_inverse().basis_xform(shadow_offset)
	if _src is AnimatedSprite2D:
		var anim := _src as AnimatedSprite2D
		var sprite := _copy as Sprite2D
		var frames := anim.sprite_frames
		sprite.texture = frames.get_frame_texture(anim.animation, anim.frame) \
				if frames != null and frames.has_animation(anim.animation) else null
		sprite.flip_h = anim.flip_h
		sprite.flip_v = anim.flip_v
		sprite.centered = anim.centered
		sprite.offset = anim.offset
	elif _src is Sprite2D:
		var src_sprite := _src as Sprite2D
		var sprite := _copy as Sprite2D
		sprite.texture = src_sprite.texture
		sprite.flip_h = src_sprite.flip_h
		sprite.flip_v = src_sprite.flip_v
		sprite.centered = src_sprite.centered
		sprite.offset = src_sprite.offset
	elif _src is Line2D:
		(_copy as Line2D).points = (_src as Line2D).points

## Textura de una banda que se desvanece hacia los bordes (a lo ancho de la cuerda).
static func _soft_band() -> Texture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = 4
	tex.height = 32
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	return tex
