extends Control
class_name SpriteDigitDisplay
## Renders text using 64x64 7-segment digit spritesheets.

enum Sheet { GREEN, RED, YELLOW }

const CELL_SIZE := 64

const SHEET_PATHS: Dictionary = {
	Sheet.GREEN: "res://assets/hud/digits_green.png",
	Sheet.RED: "res://assets/hud/digits_red.png",
	Sheet.YELLOW: "res://assets/hud/digits_yellow.png",
}

const DIGIT_GRID: Dictionary = {
	"0": Vector2i(0, 0),
	"1": Vector2i(1, 0),
	"2": Vector2i(2, 0),
	"3": Vector2i(3, 0),
	"4": Vector2i(4, 0),
	"5": Vector2i(0, 1),
	"6": Vector2i(2, 1),
	"7": Vector2i(3, 1),
	"8": Vector2i(4, 1),
	"9": Vector2i(5, 1),
	"-": Vector2i(5, 0),
	" ": Vector2i(5, 0),
}

const BLANK_GRID := Vector2i(5, 0)

@export var digit_height: float = 56.0
@export var digit_spacing: float = 1.0
@export var slot_count: int = 2

var _center: CenterContainer
var _row: HBoxContainer
var _current_sheet: Sheet = Sheet.GREEN
var _current_text: String = ""


func _ready() -> void:
	_center = CenterContainer.new()
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_center)

	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", int(digit_spacing))
	_center.add_child(_row)

	_update_slot_size()


func _update_slot_size() -> void:
	var row_w := slot_count * digit_height + maxi(slot_count - 1, 0) * digit_spacing
	custom_minimum_size = Vector2(row_w, digit_height)
	if _center:
		_center.custom_minimum_size = custom_minimum_size


func set_display(text: String, sheet: Sheet) -> void:
	_current_text = text
	_current_sheet = sheet
	if is_node_ready():
		_rebuild()
	else:
		call_deferred("_rebuild")


func _rebuild() -> void:
	if _row == null:
		return
	for child in _row.get_children():
		child.queue_free()

	var atlas_tex: Texture2D = load(SHEET_PATHS[_current_sheet]) as Texture2D
	if atlas_tex == null:
		return
	for ch in _current_text:
		var grid: Vector2i = DIGIT_GRID.get(ch, BLANK_GRID)
		var digit := TextureRect.new()
		digit.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		digit.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		digit.custom_minimum_size = Vector2(digit_height, digit_height)
		digit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		digit.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		var region := AtlasTexture.new()
		region.atlas = atlas_tex
		region.region = Rect2(grid.x * CELL_SIZE, grid.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		digit.texture = region
		_row.add_child(digit)
