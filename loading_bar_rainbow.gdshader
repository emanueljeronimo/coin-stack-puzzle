shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform float rainbow_sat : hint_range(0.0, 1.0) = 0.78;
uniform float rainbow_val : hint_range(0.5, 1.0) = 0.98;
uniform float pastel_mix : hint_range(0.0, 0.8) = 0.08;
uniform float scroll_speed : hint_range(0.0, 0.4) = 0.07;

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	float hue = fract(0.02 + UV.x * 0.92 + TIME * scroll_speed);
	vec3 rainbow = hsv2rgb(vec3(hue, rainbow_sat, rainbow_val));
	rainbow = mix(rainbow, vec3(1.0), pastel_mix);
	COLOR = vec4(rainbow, 1.0);
}
