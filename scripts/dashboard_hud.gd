extends Node3D
## In-dash LED displays flanking the steering wheel.

const THREE_SECOND_RULE := 3.0
## Top edge of Cockpit/Dashboard mesh (y=-0.38 + half height 0.175).
const DASHBOARD_TOP_Y := -0.205
const DISPLAY_Z := -0.48
const SIDE_DISPLAY_X := 0.36

var _distance_display: LedDisplay
var _gap_display: LedDisplay
var _speed_display: LedDisplay


func _ready() -> void:
	_speed_display = _make_speed_display()
	_distance_display = _make_side_display("MI · WORK", -SIDE_DISPLAY_X)
	_gap_display = _make_side_display("FOLLOW SEC", SIDE_DISPLAY_X)
	set_speed_mph(45.0)
	set_distance_miles(10.0)
	set_following_gap(99.0)


func _place_on_dashboard(display: LedDisplay, x: float) -> void:
	display.position = Vector3(x, DASHBOARD_TOP_Y - display.get_panel_height() * 0.5, DISPLAY_Z)


func _make_speed_display() -> LedDisplay:
	var display := LedDisplay.new()
	display.max_digits = 3
	display.digit_px = 74.0
	display.caption_text = "MPH"
	display.caption_font_size = 7.0
	display.default_sheet = FontDigitDisplay.Sheet.GREEN
	add_child(display)
	_place_on_dashboard(display, 0.0)
	return display


func _make_side_display(caption: String, x: float) -> LedDisplay:
	var display := LedDisplay.new()
	display.caption_text = caption
	display.max_digits = 2
	display.digit_px = 70.0
	display.caption_font_size = 9.0
	add_child(display)
	_place_on_dashboard(display, x)
	return display


func set_speed_mph(mph: float) -> void:
	if _speed_display:
		_speed_display.set_value(str(int(round(mph))), FontDigitDisplay.Sheet.GREEN)


func set_distance_miles(miles: float) -> void:
	if _distance_display:
		_distance_display.set_value(str(int(round(miles))), FontDigitDisplay.Sheet.GREEN)


func set_following_gap(seconds: float) -> void:
	if _gap_display == null:
		return
	if seconds >= 90.0:
		_gap_display.set_value("--", FontDigitDisplay.Sheet.GREEN)
		_gap_display.set_caption("FOLLOW")
	else:
		_gap_display.set_value(str(int(round(seconds))), _gap_sheet(seconds))
		_gap_display.set_caption("FOLLOW SEC")


func _gap_sheet(seconds: float) -> FontDigitDisplay.Sheet:
	if seconds >= THREE_SECOND_RULE:
		return FontDigitDisplay.Sheet.GREEN
	if seconds >= 1.5:
		return FontDigitDisplay.Sheet.YELLOW
	return FontDigitDisplay.Sheet.RED
