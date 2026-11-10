@tool
class_name VisualFx

## Ayudas para las sombras y brillos del juego (ver shaders/silueta.gdshader y
## shaders/caja_suave.gdshader). Todo se dibuja en capas de z FIJAS (absolutas),
## entre el fondo (-100) y el terreno (0), así una sombra nunca tapa a un objeto:
## solo oscurece el fondo que está detrás.

## Sombras de terreno y objetos.
const Z_SHADOW := -50
## Luz difusa de las zonas de peligro (encima de las sombras).
const Z_GLOW := -40
## Halo / sombra con la forma de las zonas de peligro.
const Z_HALO := -30
## Luz que tiñe lo que está cerca (terreno, jugadores): encima de todo el mundo.
const Z_LIGHT := 10

## De dónde viene la luz: las sombras caen hacia abajo a la derecha.
const LIGHT_OFFSET := Vector2(5, 7)

const BOX_SHADER := preload("res://shaders/caja_suave.gdshader")
const SILHOUETTE_SHADER := preload("res://shaders/silueta.gdshader")

## Agrega a [param parent] un rectángulo difuso (sombra o luz) alrededor de la caja
## de tamaño [param size] centrada en [param center] (coordenadas de [param parent]).
## [param params] son uniforms de caja_suave.gdshader (tint, offset, radius…).
## [param margin] = cuánto se extiende afuera de la caja (px).
static func soft_box(parent: Node, size: Vector2, center: Vector2, margin: float, z: int,
		params: Dictionary, node_name := "SoftBox") -> ColorRect:
	var rect := ColorRect.new()
	rect.name = node_name
	rect.color = Color.WHITE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.position = center - size * 0.5 - Vector2(margin, margin)
	rect.size = size + Vector2(margin, margin) * 2.0
	rect.z_index = z
	rect.z_as_relative = false
	var mat := ShaderMaterial.new()
	mat.shader = BOX_SHADER
	mat.set_shader_parameter("box_size", size)
	mat.set_shader_parameter("margin", Vector2(margin, margin))
	for key in params:
		mat.set_shader_parameter(key, params[key])
	rect.material = mat
	parent.add_child(rect)
	return rect

## Material de silueta (sombra o luz con la forma de la textura del sprite).
## [param params] son uniforms de silueta.gdshader (tint, blur_px, additive…).
static func silhouette_material(params: Dictionary) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SILHOUETTE_SHADER
	for key in params:
		mat.set_shader_parameter(key, params[key])
	return mat
