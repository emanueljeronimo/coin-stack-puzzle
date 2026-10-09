shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform float span_px = 400.0;
uniform float rainbow_sat : hint_range(0.0, 1.0) = 0.62;
uniform float rainbow_val : hint_range(0.5, 1.0) = 0.96;
uniform float pastel_mix : hint_range(0.0, 0.8) = 0.12;

varying float v_x;

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void vertex() {
	v_x = VERTEX.x;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = dot(COLOR.rgb, vec3(0.33, 0.5, 0.17));
	float t = clamp(v_x / max(span_px, 1.0), 0.0, 1.0);
	float hue = fract(0.94 - t * 0.78);
	vec3 rainbow = hsv2rgb(vec3(hue, rainbow_sat, rainbow_val));
	rainbow = mix(rainbow, vec3(1.0), pastel_mix);
	float keep_outline = step(lum, 0.42);
	vec3 out_col = mix(rainbow, COLOR.rgb, keep_outline);
	COLOR = vec4(out_col, tex.a * COLOR.a);
}
