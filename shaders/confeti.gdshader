shader_type canvas_item;

// Papel de confetti que da vueltas en el aire: el alto visible del papelito va y
// vuelve (como si girara en 3D) y se oscurece al quedar de canto. Para
// CPUParticles2D (scenes/fx/win_confetti.tscn): usa INSTANCE_CUSTOM.y (edad de la
// partícula, 0..1) y INSTANCE_CUSTOM.z (azar por partícula: anim_offset 0..1).

// Medias vueltas en toda la vida de la partícula (a la velocidad media).
uniform float flips = 16.0;
// Variación de la rapidez del giro entre papelitos (0 = todos igual).
uniform float flip_variation : hint_range(0.0, 1.0) = 0.6;
// Cuánto se oscurece de canto (0 = nada).
uniform float edge_shade : hint_range(0.0, 1.0) = 0.45;

varying float v_phase;

void vertex() {
	float seed = INSTANCE_CUSTOM.z;
	float rate = flips * (1.0 - flip_variation * 0.5 + flip_variation * fract(seed * 7.13));
	v_phase = INSTANCE_CUSTOM.y * rate * PI + seed * TAU;
}

void fragment() {
	float h = abs(cos(v_phase));
	// Alto visible del papelito (nunca 0 del todo: queda una rayita de canto).
	float inside = step(abs(UV.y - 0.5) * 2.0, max(h, 0.12));
	COLOR.rgb *= 1.0 - edge_shade * (1.0 - h);
	COLOR.a *= inside;
}
