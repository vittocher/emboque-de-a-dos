shader_type canvas_item;
render_mode blend_add;

// Destello para partículas: un punto brillante con 4 rayos (estrella) y un halo
// suave. Se suma al fondo (luz). El color sale de la partícula (color / ramp).
// Lo usan las partículas doradas del emboque (scenes/fx/emboque_burst.tscn).

// Largo/fuerza de los rayos (0 = solo el punto con halo).
uniform float rays : hint_range(0.0, 1.0) = 0.8;
// Finura de los rayos (más alto = más finos).
uniform float ray_sharpness : hint_range(4.0, 60.0) = 26.0;
// Tamaño del centro (fracción del cuadro).
uniform float core_size : hint_range(0.02, 0.6) = 0.16;
// Halo difuso alrededor.
uniform float halo : hint_range(0.0, 1.0) = 0.35;
// Cuánto se blanquea el centro (lo más caliente de la luz).
uniform float white_core : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	vec2 d = (UV - 0.5) * 2.0; // -1..1
	float r = length(d);
	float core = exp(-r * r / (core_size * core_size));
	float ray_x = exp(-abs(d.y) * ray_sharpness) * (1.0 - smoothstep(0.0, 1.0, abs(d.x)));
	float ray_y = exp(-abs(d.x) * ray_sharpness) * (1.0 - smoothstep(0.0, 1.0, abs(d.y)));
	float glow = exp(-r * r * 5.0) * halo * (1.0 - smoothstep(0.7, 1.0, r));
	float a = clamp(core + (ray_x + ray_y) * rays + glow, 0.0, 1.0);
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), core * white_core);
	COLOR.a *= a;
}
