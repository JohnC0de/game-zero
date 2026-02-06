shader_type canvas_item;

uniform float opacity : hint_range(0.0, 1.0) = 0.06;
uniform float scale : hint_range(1.0, 800.0) = 280.0;
uniform float speed : hint_range(0.0, 5.0) = 1.1;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV * scale;
	uv += vec2(TIME * speed * 13.0, TIME * speed * 17.0);
	float n = hash(floor(uv));
	float a = opacity * (n - 0.5);
	COLOR = vec4(tint.rgb, abs(a));
}
