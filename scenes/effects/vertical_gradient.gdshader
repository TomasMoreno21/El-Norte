shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.25, 0.5, 0.25, 0.85);
uniform vec4 bottom_color : source_color = vec4(0.1, 0.22, 0.1, 0.85);

void fragment() {
	COLOR = mix(top_color, bottom_color, UV.y);
}
