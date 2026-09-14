shader_type canvas_item;

// Arcoíris pastel, mismo relieve que las fichas normales.
uniform float rainbow_spin : hint_range(0.0, 4.0) = 0.35;
uniform float rainbow_sat : hint_range(0.0, 1.0) = 0.42;
uniform float pastel_soften : hint_range(0.0, 0.5) = 0.16;
uniform float volume_amount : hint_range(0.0, 1.0) = 0.28;
uniform float face_lift : hint_range(0.5, 1.0) = 0.90;

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 face_tex = texture(TEXTURE, vec2(0.5, 0.5));
	vec2 p = UV * 2.0 - 1.0;
	float ang = atan(p.y, p.x) / TAU + 0.5;
	float hue = fract(ang + TIME * rainbow_spin);
	vec3 rainbow = hsv2rgb(vec3(hue, rainbow_sat, 0.92));
	rainbow = mix(rainbow, vec3(1.0), pastel_soften);

	float lum = max(dot(tex.rgb, vec3(0.299, 0.587, 0.114)), 0.001);
	float face = max(dot(face_tex.rgb, vec3(0.299, 0.587, 0.114)), 0.001);
	float lifted = mix(face_lift, lum, 0.28);
	float hi = max(lum - face, 0.0);
	float lit = clamp(lifted + hi * volume_amount, 0.0, 1.05);
	float scale = lit / lum;

	COLOR.rgb = rainbow * tex.rgb * scale;
	COLOR.a *= tex.a;
}
