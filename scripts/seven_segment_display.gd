extends Control
class_name SevenSegmentDisplay
## Procedural neon 7-segment LED digit renderer with chamfered segments.

var display_text: String = "0.0"
var neon_color: Color = Color(0.0, 1.0, 0.92, 1.0)

const PATTERNS: Dictionary = {
	"0": 0x3F, "1": 0x06, "2": 0x5B, "3": 0x4F, "4": 0x66,
	"5": 0x6D, "6": 0x7D, "7": 0x07, "8": 0x7F, "9": 0x6F,
	"-": 0x40, " ": 0x00,
}

const GHOST_COLOR := Color(0.07, 0.07, 0.1, 0.28)


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
	var digit_w := slot_w * 0.9
	var digit_h := size.y * 0.86
	var start_x := _centered_start_x(slot_w)
	var y := size.y * 0.07

	var x := start_x
	for ch in display_text:
		if ch == ".":
			_draw_decimal(x, y, digit_w, digit_h)
			x += slot_w * 0.34
		else:
			var pattern: int = PATTERNS.get(ch, 0x00)
			_draw_digit_layers(x, y, digit_w, digit_h, pattern)
			x += slot_w


func _slot_count() -> float:
	var slots := 0.0
	for ch in display_text:
		if ch == ".":
			slots += 0.34
		else:
			slots += 1.0
	return maxf(slots, 1.0)


func _centered_start_x(slot_w: float) -> float:
	var total := 0.0
	for ch in display_text:
		if ch == ".":
			total += slot_w * 0.34
		else:
			total += slot_w
	return (size.x - total) * 0.5


func _metrics(w: float, h: float, thickness_scale: float) -> Dictionary:
	var t := clampf(maxf(3.0, w * 0.125) * thickness_scale, 2.5, w * 0.19)
	var chamfer := minf(t * 0.42, t * 0.42)
	var horiz := maxf(w - t * 2.2, t * 2.5)
	var vert := maxf((h - t * 3.3) * 0.5, t * 1.8)
	var gap := t * 0.12
	return {"t": t, "chamfer": chamfer, "horiz": horiz, "vert": vert, "gap": gap}


func _draw_digit_layers(ox: float, oy: float, w: float, h: float, pattern: int) -> void:
	for seg in 7:
		_draw_segment(seg, ox, oy, w, h, GHOST_COLOR, 1.0)

	for seg in 7:
		if pattern & (1 << seg):
			var glow := Color(neon_color.r, neon_color.g, neon_color.b, 0.24)
			_draw_segment(seg, ox, oy, w, h, glow, 1.28)
			var body := Color(
				minf(neon_color.r * 1.05, 1.0),
				minf(neon_color.g * 1.05, 1.0),
				minf(neon_color.b * 1.05, 1.0),
				0.95
			)
			_draw_segment(seg, ox, oy, w, h, body, 1.0)
			var core := Color(1.0, 1.0, 1.0, 0.82).lerp(neon_color, 0.2)
			_draw_segment(seg, ox, oy, w, h, core, 0.5)


func _draw_segment(seg: int, ox: float, oy: float, w: float, h: float, color: Color, thickness_scale: float) -> void:
	var m := _metrics(w, h, thickness_scale)
	var t: float = m.t
	var chamfer: float = m.chamfer
	var horiz: float = m.horiz
	var vert: float = m.vert
	var gap: float = m.gap

	match seg:
		0:
			_draw_h_segment(ox + t, oy + gap, horiz, t, chamfer, color)
		1:
			_draw_v_segment(ox + w - t, oy + t + gap, t, vert, chamfer, color)
		2:
			_draw_v_segment(ox + w - t, oy + t * 2.0 + vert + gap, t, vert, chamfer, color)
		3:
			_draw_h_segment(ox + t, oy + h - t - gap, horiz, t, chamfer, color)
		4:
			_draw_v_segment(ox, oy + t * 2.0 + vert + gap, t, vert, chamfer, color)
		5:
			_draw_v_segment(ox, oy + t + gap, t, vert, chamfer, color)
		6:
			_draw_h_segment(ox + t, oy + t + vert + gap, horiz, t, chamfer, color)


func _draw_h_segment(x: float, y: float, length: float, thickness: float, chamfer: float, color: Color) -> void:
	var c := minf(chamfer, minf(length * 0.48, thickness * 0.48))
	if length <= c * 2.0 or thickness <= 0.5:
		return
	var pts := PackedVector2Array([
		Vector2(x + c, y),
		Vector2(x + length - c, y),
		Vector2(x + length, y + thickness * 0.5),
		Vector2(x + length - c, y + thickness),
		Vector2(x + c, y + thickness),
		Vector2(x, y + thickness * 0.5),
	])
	draw_colored_polygon(pts, color)


func _draw_v_segment(x: float, y: float, thickness: float, length: float, chamfer: float, color: Color) -> void:
	var c := minf(chamfer, minf(length * 0.48, thickness * 0.48))
	if length <= c * 2.0 or thickness <= 0.5:
		return
	var pts := PackedVector2Array([
		Vector2(x, y + c),
		Vector2(x + thickness * 0.5, y),
		Vector2(x + thickness, y + c),
		Vector2(x + thickness, y + length - c),
		Vector2(x + thickness * 0.5, y + length),
		Vector2(x, y + length - c),
	])
	draw_colored_polygon(pts, color)


func _draw_decimal(ox: float, oy: float, w: float, h: float) -> void:
	var radius := maxf(3.5, w * 0.09)
	var center := Vector2(ox + w * 0.12, oy + h - radius * 1.5)
	draw_circle(center, radius * 1.6, Color(neon_color.r, neon_color.g, neon_color.b, 0.2))
	draw_circle(center, radius, Color(
		minf(neon_color.r * 1.05, 1.0),
		minf(neon_color.g * 1.05, 1.0),
		minf(neon_color.b * 1.05, 1.0),
		0.95
	))
	draw_circle(center, radius * 0.45, Color(1.0, 1.0, 1.0, 0.85))
