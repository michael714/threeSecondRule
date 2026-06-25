extends Control
class_name FontDigitDisplay
## 7-segment style readout using the Digital-7 TrueType font.

enum Sheet { GREEN, RED, YELLOW }

const DIGITAL_FONT_PATH := "res://digits/digital-7.regular.ttf"

const NEON_COLORS: Dictionary = {
	Sheet.GREEN: Color(0.1, 1.0, 0.22, 1.0),
	Sheet.RED: Color(1.0, 0.1, 0.06, 1.0),
	Sheet.YELLOW: Color(1.0, 0.82, 0.04, 1.0),
}

const DIGIT_WIDTH_RATIO := 0.56

@export var slot_count: int = 2
@export var digit_height: float = 70.0

var _label: Label
var _current_sheet: Sheet = Sheet.GREEN
var _display_text: String = "0"


func _ready() -> void:
	custom_minimum_size = Vector2(_row_width(), digit_height)
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_label)
	_apply_text()


func set_display(text: String, sheet: Sheet) -> void:
	_display_text = text
	_current_sheet = sheet
	if is_node_ready():
		_apply_text()


func _row_width() -> float:
	return slot_count * digit_height * DIGIT_WIDTH_RATIO


func _apply_text() -> void:
	if _label == null:
		return
	_label.text = _display_text
	_label.label_settings = _make_digit_settings(_current_sheet)


func _make_digit_settings(sheet: Sheet) -> LabelSettings:
	var settings := LabelSettings.new()
	var font_file := load(DIGITAL_FONT_PATH) as FontFile
	settings.font = font_file
	settings.font_size = int(digit_height * 0.92)
	var neon: Color = NEON_COLORS[sheet]
	settings.font_color = neon
	settings.outline_size = 2
	settings.outline_color = Color(neon.r * 0.35, neon.g * 0.35, neon.b * 0.35, 0.85)
	settings.shadow_size = 12
	settings.shadow_color = Color(neon.r, neon.g, neon.b, 0.5)
	settings.shadow_offset = Vector2.ZERO
	return settings
