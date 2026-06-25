extends Node3D
class_name LedDisplay
## In-dash 7-segment readout rendered via SubViewport (Digital-7 TTF).

@export var caption_text: String = "READOUT"
@export var max_digits: int = 2
@export var digit_px: float = 70.0
@export var caption_font_size: float = 10.0
@export var show_caption: bool = true
@export var default_sheet: FontDigitDisplay.Sheet = FontDigitDisplay.Sheet.GREEN

const FRAME_MARGIN := 3.0
const FRAME_SEP := 1.0
const DIGIT_FONT_PATH := "res://digits/digital-7.regular.ttf"

var _digits: FontDigitDisplay
var _caption_label: Label
var _viewport: SubViewport
var _panel_size: Vector2 = Vector2.ZERO


func get_panel_height() -> float:
	return _panel_size.y


func _ready() -> void:
	_build()


func set_value(text: String, sheet: FontDigitDisplay.Sheet) -> void:
	if _digits:
		_digits.set_display(text, sheet)
		_update_bezel(_accent_for_sheet(sheet))


func set_caption(text: String) -> void:
	if _caption_label == null:
		return
	_caption_label.text = text
	_apply_caption_neon()


func _build() -> void:
	var caption_px := caption_font_size if show_caption else 0.0
	var digit_row_w := max_digits * digit_px * FontDigitDisplay.DIGIT_WIDTH_RATIO
	var viewport_w := int(digit_row_w + FRAME_MARGIN * 2.0)
	var viewport_h := int(FRAME_MARGIN * 2.0 + digit_px + (FRAME_SEP + caption_px if show_caption else 0.0))
	var panel_size := Vector2(viewport_w * 0.36 / 380.0, viewport_h * 0.148 / 128.0)
	_panel_size = panel_size

	_viewport = SubViewport.new()
	_viewport.size = Vector2i(viewport_w, viewport_h)
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewport.add_child(panel)
	panel.add_theme_stylebox_override("panel", _make_bezel(_accent_for_sheet(default_sheet)))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(FRAME_MARGIN))
	margin.add_theme_constant_override("margin_right", int(FRAME_MARGIN))
	margin.add_theme_constant_override("margin_top", int(FRAME_MARGIN))
	margin.add_theme_constant_override("margin_bottom", int(FRAME_MARGIN))
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(FRAME_SEP))
	margin.add_child(vbox)

	_digits = FontDigitDisplay.new()
	_digits.slot_count = max_digits
	_digits.digit_height = digit_px
	_digits.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_digits.custom_minimum_size = Vector2(digit_row_w, digit_px)
	vbox.add_child(_digits)

	if show_caption:
		_caption_label = _make_caption_label()
		_caption_label.text = caption_text
		vbox.add_child(_caption_label)

	var screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = panel_size
	screen.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _viewport.get_texture()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen.material_override = mat
	add_child(screen)

	set_value("0", default_sheet)


func _accent_for_sheet(sheet: FontDigitDisplay.Sheet) -> Color:
	match sheet:
		FontDigitDisplay.Sheet.GREEN:
			return Color(0.2, 1.0, 0.35, 1.0)
		FontDigitDisplay.Sheet.RED:
			return Color(1.0, 0.2, 0.15, 1.0)
		FontDigitDisplay.Sheet.YELLOW:
			return Color(1.0, 0.85, 0.15, 1.0)
	return Color(0.2, 1.0, 0.35, 1.0)


func _make_bezel(accent: Color) -> StyleBoxFlat:
	var bezel := StyleBoxFlat.new()
	bezel.bg_color = Color(0.01, 0.01, 0.03, 0.98)
	bezel.border_color = Color(accent.r, accent.g, accent.b, 0.65)
	bezel.set_border_width_all(1)
	bezel.set_corner_radius_all(2)
	bezel.shadow_color = Color(accent.r, accent.g, accent.b, 0.22)
	bezel.shadow_size = 4
	return bezel


func _update_bezel(accent: Color) -> void:
	var panel := _viewport.get_child(0) as PanelContainer
	if panel:
		panel.add_theme_stylebox_override("panel", _make_bezel(accent))


func _make_caption_label() -> Label:
	var label := Label.new()
	var settings := LabelSettings.new()
	var font_file := load(DIGIT_FONT_PATH) as FontFile
	settings.font = font_file
	settings.font_size = int(caption_font_size)
	settings.font_color = Color(0.45, 0.72, 0.45, 0.85)
	settings.outline_size = 1
	settings.outline_color = Color(0.15, 0.3, 0.15, 0.6)
	settings.shadow_size = 4
	settings.shadow_color = Color(0.35, 0.65, 0.35, 0.25)
	settings.shadow_offset = Vector2.ZERO
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _apply_caption_neon() -> void:
	if _caption_label == null:
		return
	var settings := _caption_label.label_settings.duplicate()
	settings.font_size = int(caption_font_size)
	settings.font_color = Color(0.45, 0.72, 0.45, 0.85)
	settings.shadow_color = Color(0.35, 0.65, 0.35, 0.25)
	_caption_label.label_settings = settings
