shader_type canvas_item;

uniform float border_width = 30.0;
uniform float flash_alpha;

void fragment() {
	vec2 size = 1.0 / SCREEN_PIXEL_SIZE;
	float bw = border_width / size.x;
	float edge_x = min(UV.x, 1.0 - UV.x);
	float edge_y = min(UV.y, 1.0 - UV.y);
	float edge = min(edge_x, edge_y);
	COLOR = vec4(0.0, 1.0, 0.0, float(edge < bw) * flash_alpha);
}
