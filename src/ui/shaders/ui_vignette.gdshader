shader_type canvas_item;

uniform float opacity : hint_range(0.0, 1.0) = 0.28;
uniform float softness : hint_range(0.1, 3.0) = 1.6;
uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float v = pow(clamp(r, 0.0, 1.0), softness);
	float a = opacity * v;
	COLOR = vec4(tint.rgb, a);
}
