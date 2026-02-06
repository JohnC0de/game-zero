shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.12;
uniform float density : hint_range(100.0, 2000.0) = 900.0;
uniform float speed : hint_range(0.0, 2.0) = 0.18;
uniform float sharpness : hint_range(1.0, 16.0) = 8.0;

void fragment() {
	float t = (UV.y * density) + (TIME * speed * density);
	float s = sin(t * 3.1415926);
	float v = pow(clamp((s * 0.5) + 0.5, 0.0, 1.0), sharpness);
	float a = opacity * v;
	COLOR = vec4(line_color.rgb, a);
}
