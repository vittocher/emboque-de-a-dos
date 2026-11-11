shader_type canvas_item;

// Ajuste HSV (tono, saturación, brillo) + contraste del dibujo de un sprite, y un
// contorno de color que puede latir. Lo usa la caja empujable para distinguirse
// del terreno (se ve que es un objeto con el que se interactúa).
// Godot no trae ajuste HSV por píxel para texturas: modulate solo multiplica RGB.
// Supone un sprite centrado (Sprite2D / AnimatedSprite2D con centered = true).

group_uniforms Color;
// Gira el tono (fracción de la vuelta: 0.05 = 18°, hacia el amarillo/naranja en la madera).
uniform float hue_shift : hint_range(-0.5, 0.5) = 0.0;
// Multiplica la saturación (1 = igual).
uniform float saturation : hint_range(0.0, 3.0) = 1.0;
// Multiplica el brillo (valor) (1 = igual).
uniform float value : hint_range(0.0, 3.0) = 1.0;
// Contraste alrededor del gris medio (1 = igual).
uniform float contrast : hint_range(0.0, 3.0) = 1.0;

group_uniforms Contorno;
uniform vec4 outline_color : source_color = vec4(1.0, 0.85, 0.4, 1.0);
// Grosor del contorno en px del mundo (0 = sin contorno).
uniform float outline_px : hint_range(0.0, 8.0) = 0.0;
// Cuánto baja el contorno al latir (0 = fijo) y su rapidez.
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_speed = 2.5;
group_uniforms;

// UV agrandado sin recortar (Godot recorta el UV de los sprites a 0..1 antes del
// fragment; ver silueta.gdshader).
varying vec2 v_uv;
// Modulate del nodo. En el fragment, COLOR ya viene multiplicado por la textura en
// el UV recortado: no sirve como modulate (oscurecía / recortaba el dibujo).
varying vec4 v_modulate;
varying vec2 v_px_uv;

// Alfa de la textura en uv; 0 fuera de ella.
#define ALPHA_AT(uv) (texture(TEXTURE, clamp((uv), vec2(0.0), vec2(1.0))).a * step(0.0, (uv).x) * step((uv).x, 1.0) * step(0.0, (uv).y) * step((uv).y, 1.0))

vec3 rgb_to_hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

void vertex() {
	v_modulate = COLOR;
	vec2 s = max(vec2(length(MODEL_MATRIX[0].xy), length(MODEL_MATRIX[1].xy)), vec2(0.0001));
	if (outline_px > 0.0) {
		// Agranda el cuadro para que el contorno quepa fuera del dibujo.
		vec2 margin = vec2(outline_px + 1.0) / s;
		VERTEX += sign(VERTEX) * margin;
		UV += sign(UV - 0.5) * margin * TEXTURE_PIXEL_SIZE;
	}
	v_uv = UV;
	v_px_uv = outline_px / s * TEXTURE_PIXEL_SIZE;
}

void fragment() {
	vec2 uv = v_uv;
	vec4 tex = texture(TEXTURE, clamp(uv, vec2(0.0), vec2(1.0)));
	tex.a *= ALPHA_AT(uv) > 0.0 ? 1.0 : 0.0;

	vec3 hsv = rgb_to_hsv(tex.rgb);
	hsv.x = fract(hsv.x + hue_shift);
	hsv.y = clamp(hsv.y * saturation, 0.0, 1.0);
	hsv.z *= value;
	vec3 rgb = (hsv_to_rgb(hsv) - 0.5) * contrast + 0.5;
	vec4 col = vec4(clamp(rgb, 0.0, 1.0), tex.a);

	if (outline_px > 0.0) {
		// Contorno: hay dibujo a menos de outline_px de este píxel.
		float o = 0.0;
		for (int i = 0; i < 12; i++) {
			float ang = float(i) * 0.5236;
			vec2 d = vec2(cos(ang), sin(ang)) * v_px_uv;
			o = max(o, ALPHA_AT(uv + d));
			o = max(o, ALPHA_AT(uv + d * 0.5));
		}
		float k = outline_color.a * (1.0 - pulse * (0.5 + 0.5 * sin(TIME * pulse_speed)));
		float la = o * k * (1.0 - col.a);
		float a = col.a + la;
		col = vec4((col.rgb * col.a + outline_color.rgb * la) / max(a, 0.0001), a);
	}
	COLOR = col * v_modulate;
}
