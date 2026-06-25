extends Control
class_name DotMatrixDisplay
## Dot-matrix pixel digit renderer (4x7 grid per character).

var display_text: String = "0.0"
var neon_color: Color = Color(0.0, 1.0, 0.92, 1.0)

const COLS := 4
const ROWS := 7

const GRIDS: Dictionary = {
	"0": ["0110", "1001", "1001", "1001", "1001", "1001", "0110"],
	"1": ["0100", "1100", "0100", "0100", "0100", "0100", "0110"],
	"2": ["0111", "1000", "1000", "0110", "0010", "0010", "1110"],
	"3": ["1110", "0010", "0010", "0110", "0010", "0010", "1110"],
	"4": ["1001", "1001", "1001", "1111", "0001", "0001", "0001"],
	"5": ["1111", "1000", "1000", "1110", "0010", "0010", "1110"],
	"6": ["0110", "1000", "1000", "1110", "1001", "1001", "0110"],
	"7": ["1111", "0001", "0001", "0010", "0010", "0100", "0100"],
	"8": ["0110", "1001", "1001", "0110", "1001", "1001", "0110"],
	"9": ["0110", "1001", "1001", "0111", "0010", "0010", "0110"],
	"-": ["0000", "0000", "0000", "1111", "0000", "0000", "0000"],
	".": ["0000", "0000", "0000", "0000", "0000", "0110", "0110"],
}

const GHOST_PIXEL := Color(0.11, 0.07, 0.06, 0.38)


func set_display(text: String, color: Color) -> void:
	display_text = text
	neon_color = color
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if display_text.is_empty():
		return

	var slot_w := size.x / _slot_count()
	var digit_w := slot_w * 0.88
	var digit_h := size.y * 0.9
	var start_x := _centered_start_x(slot_w)
	var y := size.y * 0.05

	var x := start_x
	for ch in display_text:
		var grid: Array = GRIDS.get(ch, _blank_grid())
		_draw_character(x, y, digit_w, digit_h, grid)
		x += slot_w


func _slot_count() -> float:
	var slots := 0.0
	for ch in display_text:
		if ch == ".":
			slots += 0.38
		else:
			slots += 1.0
	return maxf(slots, 1.0)


func _centered_start_x(slot_w: float) -> float:
	var total := 0.0
	for ch in display_text:
		if ch == ".":
			total += slot_w * 0.38
		else:
			total += slot_w
	return (size.x - total) * 0.5


func _blank_grid() -> Array:
	var rows: Array = []
	for _i in ROWS:
		rows.append("0000")
	return rows


func _draw_character(ox: float, oy: float, w: float, h: float, grid: Array) -> void:
	var gap_x := maxf(1.0, w * 0.006)
	var gap_y := maxf(1.5, h * 0.014)
	var pixel_w := (w - gap_x * (COLS - 1)) / COLS
	var pixel_h := (h - gap_y * (ROWS - 1)) / ROWS
	var pixel_size := minf(pixel_w, pixel_h) * 0.97

	var grid_w := COLS * pixel_size + gap_x * (COLS - 1)
	var grid_h := ROWS * pixel_size + gap_y * (ROWS - 1)
	var offset_x := ox + (w - grid_w) * 0.5
	var offset_y := oy + (h - grid_h) * 0.5
	var step_x := pixel_size + gap_x
	var step_y := pixel_size + gap_y

	for row in ROWS:
		var row_str: String = grid[row]
		for col in COLS:
			var lit := row_str[col] == "1"
			var cx := offset_x + col * step_x + pixel_size * 0.5
			var cy := offset_y + row * step_y + pixel_size * 0.5
			_draw_pixel(cx, cy, pixel_size, lit)


func _draw_pixel(cx: float, cy: float, pixel_size: float, lit: bool) -> void:
	var half := pixel_size * 0.5
	var rect := Rect2(cx - half, cy - half, pixel_size, pixel_size)
	draw_rect(rect, GHOST_PIXEL, true)

	if not lit:
		return

	var glow := Color(neon_color.r, neon_color.g, neon_color.b, 0.28)
	var body := Color(
		minf(neon_color.r * 1.08, 1.0),
		minf(neon_color.g * 1.08, 1.0),
		minf(neon_color.b * 1.08, 1.0),
		0.96
	)
	var core := Color(1.0, 1.0, 1.0, 0.75).lerp(neon_color, 0.15)

	var glow_rect := rect.grow(pixel_size * 0.22)
	draw_rect(glow_rect, glow, true)
	draw_rect(rect, body, true)
	var core_size := pixel_size * 0.42
	draw_rect(
		Rect2(cx - core_size * 0.5, cy - core_size * 0.5, core_size, core_size),
		core,
		true
	)
