shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(0.1, 0.3, 0.5, 0.4);
uniform vec4 bg_color : source_color = vec4(0.02, 0.02, 0.05, 1.0);
uniform float grid_size : hint_range(20.0, 200.0) = 50.0;
uniform float line_width : hint_range(0.5, 5.0) = 1.0;
uniform vec2 offset = vec2(0.0, 0.0);

void fragment() {
	vec2 uv = (UV * vec2(1920.0, 1080.0) + offset) / grid_size;
	
	// Create grid lines
	vec2 grid = abs(fract(uv - 0.5) - 0.5) / fwidth(uv);
	float line = min(grid.x, grid.y);
	float alpha = 1.0 - min(line / line_width, 1.0);
	
	// Mix background with lines
	COLOR = mix(bg_color, line_color, alpha * line_color.a);
}
