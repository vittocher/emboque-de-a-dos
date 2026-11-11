shader_type canvas_item;

// Viñeta de pantalla completa para la subida de tensión (scenes/fx/tension_fx.tscn):
// oscurece los bordes para que la mirada vaya al centro. TensionFx anima strength.

// Cuánto oscurece (0 = nada; 1 = el color pleno en las esquinas).
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(0.02, 0.01, 0.05, 1.0);
// Dónde empieza a oscurecer (0 = centro, 1 = borde) y qué tan difuso es.
uniform float radius : hint_range(0.0, 1.5) = 0.35;
uniform float softness : hint_range(0.05, 1.5) = 0.75;

void fragment() {
	// Elíptica: la pantalla es 16:9.
	float d = length((UV - 0.5) * vec2(1.0, 0.75)) * 2.0;
	float v = smoothstep(radius, radius + softness, d);
	COLOR = vec4(color.rgb, v * strength * color.a);
}
