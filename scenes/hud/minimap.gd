extends Control

const BIOME_COLORS := {
	"Cordillera": Color(0.15, 0.25, 0.5),
	"Llanuras": Color(0.25, 0.55, 0.25),
	"Puna": Color(0.55, 0.2, 0.15),
}

const BIOMES := [
	{ "name": "Cordillera", "start": 0, "end": 2200 },
	{ "name": "Llanuras", "start": 2200, "end": 4600 },
	{ "name": "Puna", "start": 4600, "end": 99999 },
]

const MAX_MAP_DIST := 5000.0
const BAR_Y := 2.0
const BAR_H := 12.0
const BAR_MARGIN := 0.1

var _distance := 0
var _current_biome := "Cordillera"

func set_distance(d: int, biome: String = "") -> void:
	_distance = d
	if biome != "":
		_current_biome = biome
	queue_redraw()

func _draw() -> void:
	if not DataManager.minimap_visible:
		return
	var w := size.x
	var bar_left := w * BAR_MARGIN
	var bar_right := w * (1.0 - BAR_MARGIN)
	var bar_w := bar_right - bar_left

	for b in BIOMES:
		var x0: float = bar_left + (float(b.start) / MAX_MAP_DIST) * bar_w
		var x1: float = bar_left + (float(mini(b.end, int(MAX_MAP_DIST))) / MAX_MAP_DIST) * bar_w
		x0 = clampf(x0, bar_left, bar_right)
		x1 = clampf(x1, bar_left, bar_right)
		var color: Color = BIOME_COLORS.get(b.name, Color.WHITE)
		var is_current: bool = b.name == _current_biome

		draw_rect(Rect2(x0, BAR_Y, x1 - x0, BAR_H), color * (1.3 if is_current else 0.8))

	var marker_x := bar_left + (float(_distance) / MAX_MAP_DIST) * bar_w
	marker_x = clampf(marker_x, bar_left, bar_right)

	var tri_size := 8.0
	var tri_y := BAR_Y + BAR_H + 1.0
	var points := PackedVector2Array([
		Vector2(marker_x, tri_y),
		Vector2(marker_x - tri_size * 0.7, tri_y + tri_size * 1.5),
		Vector2(marker_x + tri_size * 0.7, tri_y + tri_size * 1.5),
	])
	draw_colored_polygon(points, Color(1, 1, 1))
