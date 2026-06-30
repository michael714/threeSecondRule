extends Node3D
## In-dash readouts rendered via SubViewport (Digital-7 TTF, plain labels).

const THREE_SECOND_RULE := 3.0
const DIGITAL_FONT_PATH := "res://digits/digital-7.regular.ttf"
## Top edge of Cockpit/Dashboard mesh (y=-0.38 + half height 0.175).
const DASHBOARD_TOP_Y := -0.205
const DISPLAY_Z := -0.48
const SIDE_DISPLAY_X := 0.36

const VALUE_FONT_PX := 72
const CAPTION_FONT_PX := 16
const FRAME_MARGIN := 3.0
const VALUE_CAPTION_GAP := 2.0
const CAPTION_LINE_GAP := 1.0
const SIDE_VIEWPORT_W := 196
const SPEED_VIEWPORT_W := 156

const COLOR_GREEN := Color(0.1, 1.0, 0.22, 1.0)
const COLOR_YELLOW := Color(1.0, 0.82, 0.04, 1.0)
const COLOR_RED := Color(1.0, 0.1, 0.06, 1.0)
const COLOR_CAPTION := Color(0.72, 0.96, 0.72, 1.0)


class Readout:
	var value_label: Label
	var panel: PanelContainer
	var panel_height: float = 0.0


var _distance_readout: Readout
var _speed_readout: Readout
var _gap_readout: Readout


func _ready() -> void:
	_distance_readout = _make_readout(-SIDE_DISPLAY_X, SIDE_VIEWPORT_W, "Miles to", "Destination")
	_speed_readout = _make_readout(0.0, SPEED_VIEWPORT_W, "MPH", "")
	_gap_readout = _make_readout(SIDE_DISPLAY_X, SIDE_VIEWPORT_W, "Following", "Time")
	set_speed_mph(45.0)
	set_distance_miles(3.0)
	set_following_gap(99.0)


func set_speed_mph(mph: float) -> void:
	_set_readout_value(_speed_readout, str(int(round(mph))), COLOR_GREEN)


func set_distance_miles(miles: float) -> void:
	_set_readout_value(_distance_readout, "%.1f" % miles, COLOR_GREEN)


func set_following_gap(seconds: float) -> void:
	if _gap_readout == null or _gap_readout.value_label == null:
		return
	if seconds >= 90.0:
		_set_readout_value(_gap_readout, "--", COLOR_GREEN)
	else:
		_set_readout_value(_gap_readout, "%.1f" % seconds, _gap_color(seconds))


func _make_readout(x: float, viewport_w: int, caption_line1: String, caption_line2: String) -> Readout:
	var readout := Readout.new()
	var caption_lines := 2 if not caption_line2.is_empty() else 1
	var caption_block_h := CAPTION_FONT_PX * caption_lines + CAPTION_LINE_GAP * (caption_lines - 1)
	var viewport_h := int(
		FRAME_MARGIN * 2.0 + VALUE_FONT_PX + VALUE_CAPTION_GAP + caption_block_h
	)
	var panel_size := Vector2(viewport_w * 0.36 / 380.0, viewport_h * 0.148 / 128.0)
	readout.panel_height = panel_size.y

	var viewport := SubViewport.new()
	viewport.size = Vector2i(viewport_w, viewport_h)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	var root := Node3D.new()
	root.position = Vector3(x, DASHBOARD_TOP_Y - readout.panel_height * 0.5, DISPLAY_Z)
	add_child(root)
	root.add_child(viewport)

	readout.panel = PanelContainer.new()
	readout.panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(readout.panel)
	_set_readout_border(readout, COLOR_GREEN)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(FRAME_MARGIN))
	margin.add_theme_constant_override("margin_right", int(FRAME_MARGIN))
	margin.add_theme_constant_override("margin_top", int(FRAME_MARGIN))
	margin.add_theme_constant_override("margin_bottom", int(FRAME_MARGIN))
	readout.panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(VALUE_CAPTION_GAP))
	margin.add_child(vbox)

	readout.value_label = Label.new()
	readout.value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	readout.value_label.text = "0"
	readout.value_label.label_settings = _font_settings(VALUE_FONT_PX, COLOR_GREEN)
	vbox.add_child(readout.value_label)

	var caption_box := VBoxContainer.new()
	caption_box.add_theme_constant_override("separation", int(CAPTION_LINE_GAP))
	vbox.add_child(caption_box)

	var line1 := _make_caption_label(caption_line1)
	caption_box.add_child(line1)

	if not caption_line2.is_empty():
		var line2 := _make_caption_label(caption_line2)
		caption_box.add_child(line2)

	var screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = panel_size
	screen.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = viewport.get_texture()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen.material_override = mat
	root.add_child(screen)

	return readout


func _set_readout_value(readout: Readout, text: String, color: Color) -> void:
	if readout == null or readout.value_label == null:
		return
	readout.value_label.text = text
	readout.value_label.label_settings = _font_settings(VALUE_FONT_PX, color)
	_set_readout_border(readout, color)


func _set_readout_border(readout: Readout, accent: Color) -> void:
	if readout == null or readout.panel == null:
		return
	var bezel := StyleBoxFlat.new()
	bezel.bg_color = Color(0.01, 0.01, 0.03, 0.98)
	bezel.border_color = Color(accent.r, accent.g, accent.b, 0.65)
	bezel.set_border_width_all(1)
	bezel.set_corner_radius_all(2)
	readout.panel.add_theme_stylebox_override("panel", bezel)


func _make_caption_label(text: String) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = text
	label.label_settings = _font_settings(CAPTION_FONT_PX, COLOR_CAPTION)
	return label


func _font_settings(size: int, color: Color) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font = load(DIGITAL_FONT_PATH) as FontFile
	settings.font_size = size
	settings.font_color = color
	return settings


func _gap_color(seconds: float) -> Color:
	if seconds >= THREE_SECOND_RULE:
		return COLOR_GREEN
	if seconds >= 1.5:
		return COLOR_YELLOW
	return COLOR_RED
