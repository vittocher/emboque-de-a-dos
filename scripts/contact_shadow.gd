extends Node2D
class_name ContactShadow

## Sombra bajo el objeto: una mancha ovalada y difusa en el primer piso que hay
## debajo (terreno o caja), como en los plataformeros clásicos: en el aire muestra
## dónde va a caer. Se achica y se aclara al subir, hasta [member min_strength] a
## [member fade_distance] px del piso; pasada [member max_distance] (o sin piso
## debajo, sobre un foso) no se dibuja. Busca el piso con un rayo hacia abajo.
## Uso: hijo directo del cuerpo (Player, extremo del emboque). Se dibuja en la
## capa de z del cuerpo, antes que sus hermanos, así queda encima del terreno
## pero debajo del dibujo del propio objeto.

## Ancho de la mancha apoyado en el piso (px).
@export var width := 46.0
## Alto de la mancha (px).
@export var height := 12.0
## Opacidad máxima (pegado al piso).
@export_range(0.0, 1.0) var opacity := 0.7
## Altura sobre el piso a la que la mancha llega a su mínimo (px).
@export var fade_distance := 110.0
## Tamaño/opacidad mínima en el aire (0 = desaparece; > 0 = sombra permanente).
@export_range(0.0, 1.0) var min_strength := 0.0
## Hasta dónde se busca piso hacia abajo (px).
@export var max_distance := 110.0
## Cuánto más abajo del borde del piso va el centro de la mancha (px): sobre la
## cara de arriba de las tablas.
@export var sink := 3.0
## Desde dónde (relativo al cuerpo) se lanza el rayo hacia abajo.
@export var ray_origin := Vector2.ZERO
## Capas que cuentan como piso (terreno 1 + cajas 32).
@export_flags_2d_physics var floor_mask := 33

static var _texture: Texture2D

var _body: CollisionObject2D
var _strength := 0.0

func _ready() -> void:
	_body = get_parent() as CollisionObject2D
	# Primero entre los hijos del cuerpo: misma capa de z, dibujado antes que su arte.
	get_parent().move_child.call_deferred(self, 0)
	if _texture == null:
		_texture = _make_texture()

func _physics_process(_delta: float) -> void:
	if _body == null or not _body.is_inside_tree():
		return
	var from := _body.global_position + ray_origin
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, max_distance), floor_mask,
			[_body.get_rid()])
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or (hit.normal as Vector2).y > -0.5:
		_strength = 0.0
	else:
		var dist := (hit.position as Vector2).y - from.y
		_strength = maxf(clampf(1.0 - dist / fade_distance, 0.0, 1.0), min_strength)
		global_position = (hit.position as Vector2) + Vector2(0, sink)
		global_rotation = 0.0
	visible = _strength > 0.01 and _body.is_visible_in_tree()
	queue_redraw()

func _draw() -> void:
	if _strength <= 0.0:
		return
	var k := 0.45 + 0.55 * _strength
	var size := Vector2(width * k, height * k)
	draw_texture_rect(_texture, Rect2(-size * 0.5, size), false,
			Color(0, 0, 0, opacity * _strength))

static func _make_texture() -> Texture2D:
	var gradient := Gradient.new()
	# Centro casi sólido y borde difuso: se lee como sombra también sobre madera oscura.
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.85), Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	return tex
