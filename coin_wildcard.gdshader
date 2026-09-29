shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform float rainbow_sat : hint_range(0.0, 1.0) = 0.52;
uniform float rainbow_val : hint_range(0.5, 1.0) = 0.88;
uniform float pastel_mix : hint_range(0.0, 0.8) = 0.16;
uniform float relief_amount : hint_range(0.0, 1.0) = 0.85;

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = max(tex.r, max(tex.g, tex.b));
	float mask = tex.a * smoothstep(0.03, 0.11, lum);
	vec2 p = UV * 2.0 - 1.0;
	float hue = atan(p.y, p.x) / TAU + 0.5;
	vec3 rainbow = hsv2rgb(vec3(hue, rainbow_sat, rainbow_val));
	rainbow = mix(rainbow, vec3(1.0), pastel_mix);
	vec3 lit = rainbow * mix(0.48, 1.02, lum);
	vec3 out_col = mix(rainbow, lit, relief_amount);
	COLOR = vec4(out_col, mask * COLOR.a);
}
