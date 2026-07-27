shader_type canvas_item;

uniform float corner_radius = 24.0;
uniform vec2 size_px = vec2(128.0, 128.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 p = UV * size_px;
	vec2 half_size = size_px * 0.5;
	float r = min(corner_radius, min(half_size.x, half_size.y));
	vec2 q = abs(p - half_size) - half_size + vec2(r);
	float dist = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
	float a = 1.0 - smoothstep(-1.0, 1.0, dist);
	COLOR = vec4(tex.rgb, tex.a * a);
}
