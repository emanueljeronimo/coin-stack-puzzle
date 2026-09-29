shader_type canvas_item;
render_mode blend_mix, unshaded;

// Ficha vista desde arriba: cara, aro, muescas y un poco de grosor.
uniform float volume_amount : hint_range(0.0, 1.0) = 0.42;
uniform float face_lift : hint_range(0.7, 1.2) = 1.04;
uniform float rim_mix : hint_range(0.0, 1.0) = 0.55;
uniform float rainbow_amount : hint_range(0.0, 1.0) = 0.0;
uniform float rainbow_spin : hint_range(0.0, 4.0) = 0.35;

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float r = length(p);
	float ang = atan(p.y, p.x);

	vec2 shadow_p = p - vec2(0.10, 0.22);
	float shadow_a = (1.0 - smoothstep(0.86, 1.08, length(shadow_p))) * 0.22;

	float disc = 1.0 - smoothstep(0.955, 1.015, r);
	if (disc <= 0.001 && shadow_a <= 0.001) {
		discard;
	}

	vec3 base = COLOR.rgb;
	if (rainbow_amount > 0.001) {
		float hue = fract(ang / TAU + TIME * rainbow_spin);
		vec3 rainbow = hsv2rgb(vec3(hue, 0.42, 0.94));
		base = mix(base, rainbow, rainbow_amount);
	}

	float n = 0.5 + 0.5 * cos(ang * 12.0);
	float rim = smoothstep(0.70, 0.78, r) * disc;
	float inner = smoothstep(0.54, 0.60, r) * (1.0 - smoothstep(0.68, 0.74, r));
	float face = (1.0 - smoothstep(0.68, 0.76, r)) * disc;
	float thickness = clamp((p.y + 0.15) * 0.55, 0.0, 1.0) * rim * volume_amount;

	vec3 light_dir = normalize(vec3(-0.42, -0.62, 0.68));
	vec3 nrm = normalize(vec3(p * 0.85, sqrt(max(1.0 - r * r, 0.001))));
	float ndl = clamp(dot(nrm, light_dir), 0.0, 1.0);
	float hemi = mix(0.78, 1.12, ndl);
	float center = 1.0 - smoothstep(0.0, 0.62, r);

	vec3 face_col = base * face_lift * mix(0.92, 1.10, center) * hemi;
	vec3 rim_col = mix(base * 0.62, base * 1.08, n * rim_mix) * mix(0.82, 1.12, ndl);
	vec3 side_col = base * 0.46;

	vec3 col = mix(face_col, rim_col, rim);
	col = mix(col, mix(base, vec3(1.0), 0.18), inner * 0.65);
	col = mix(col, side_col, thickness);

	float spec = pow(ndl, 18.0) * face * 0.22;
	float rim_light = pow(1.0 - abs(dot(nrm, vec3(0.0, 0.0, 1.0))), 2.0) * rim * 0.12;
	col += vec3(spec + rim_light);

	vec3 shadow_col = vec3(0.10, 0.07, 0.11);
	vec3 out_col = mix(shadow_col, col, disc);
	float alpha = max(disc * COLOR.a, shadow_a * (1.0 - disc * 0.35));
	COLOR = vec4(out_col, alpha);
}
