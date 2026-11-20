extends CanvasLayer

var player
var health_label: Label
var ammo_label: Label
var objective_label: Label
var health_bar: ProgressBar
var root: Control
var joystick_base: Panel
var joystick_knob: Panel
var joystick_center := Vector2.ZERO
var joystick_touch := -1
var look_touch := -1
var move_state := Vector2.ZERO
var smoothed_joystick := Vector2.ZERO
var screen_size := Vector2.ZERO
const JOY_RADIUS := 62.0
const LOOK_ZONE_BOTTOM := 0.68

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	screen_size = get_viewport().get_visible_rect().size
	_build_hud()
	get_viewport().size_changed.connect(_on_resize)

func set_player(value) -> void:
	player = value

func _on_resize() -> void:
	screen_size = get_viewport().get_visible_rect().size
	_layout_controls()

func _build_hud() -> void:
	objective_label = Label.new()
	objective_label.position = Vector2(28, 20)
	objective_label.add_theme_font_size_override("font_size", 22)
	objective_label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.69))
	root.add_child(objective_label)

	health_label = Label.new()
	health_label.position = Vector2(28, 54)
	health_label.text = "HEALTH 100"
	health_label.add_theme_font_size_override("font_size", 18)
	root.add_child(health_label)

	health_bar = ProgressBar.new()
	health_bar.position = Vector2(28, 82)
	health_bar.size = Vector2(210, 14)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	root.add_child(health_bar)

	ammo_label = Label.new()
	ammo_label.add_theme_font_size_override("font_size", 25)
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(ammo_label)
	ammo_label.text = "30 / 120"

	_create_joystick()
	_add_button("FIRE", "fire", Vector2(-150, -142), Vector2(116, 112), 20)
	_add_button("AIM", "aim", Vector2(-280, -132), Vector2(108, 66), 16)
	_add_button("JUMP", "jump", Vector2(-280, -210), Vector2(108, 66), 16)
	_add_button("RELOAD", "reload", Vector2(-280, -54), Vector2(108, 48), 14)
	_add_button("SPRINT", "sprint", Vector2(-410, -70), Vector2(112, 54), 14)
	_layout_controls()

func _create_joystick() -> void:
	joystick_base = Panel.new()
	joystick_base.size = Vector2(174, 174)
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(0.035, 0.055, 0.07, 0.48)
	base_style.border_color = Color(0.78, 0.84, 0.88, 0.78)
	base_style.set_border_width_all(2)
	base_style.set_corner_radius_all(87)
	joystick_base.add_theme_stylebox_override("panel", base_style)
	joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(joystick_base)

	joystick_knob = Panel.new()
	joystick_knob.size = Vector2(76, 76)
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.68, 0.77, 0.82, 0.72)
	knob_style.border_color = Color(1, 1, 1, 0.9)
	knob_style.set_border_width_all(2)
	knob_style.set_corner_radius_all(38)
	joystick_knob.add_theme_stylebox_override("panel", knob_style)
	joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(joystick_knob)

func _layout_controls() -> void:
	if not is_instance_valid(joystick_base): return
	# Anchored offsets keep controls attached to the safe bottom corners on every aspect ratio.
	joystick_base.anchor_left = 0
	joystick_base.anchor_right = 0
	joystick_base.anchor_top = 1
	joystick_base.anchor_bottom = 1
	joystick_base.offset_left = 34
	joystick_base.offset_right = 208
	joystick_base.offset_top = -208
	joystick_base.offset_bottom = -34
	joystick_center = joystick_base.global_position + joystick_base.size * 0.5
	if joystick_touch == -1:
		joystick_knob.position = joystick_center - joystick_knob.size * 0.5
	ammo_label.anchor_left = 1
	ammo_label.anchor_right = 1
	ammo_label.anchor_top = 1
	ammo_label.anchor_bottom = 1
	ammo_label.offset_left = -230
	ammo_label.offset_right = -24
	ammo_label.offset_top = -58
	ammo_label.offset_bottom = -22
	for child in root.get_children():
		if child is not Button: continue
		child.anchor_left = 1
		child.anchor_right = 1
		child.anchor_top = 1
		child.anchor_bottom = 1
		match child.name:
			"FIRE": _set_button_offsets(child, -148, -132, -24, -24)
			"AIM": _set_button_offsets(child, -276, -122, -164, -56)
			"JUMP": _set_button_offsets(child, -276, -204, -164, -138)
			"RELOAD": _set_button_offsets(child, -276, -54, -164, -10)
			"SPRINT": _set_button_offsets(child, -410, -70, -298, -16)

func _set_button_offsets(button: Button, left: float, top: float, right: float, bottom: float) -> void:
	button.offset_left = left
	button.offset_top = top
	button.offset_right = right
	button.offset_bottom = bottom

func _add_button(caption: String, action: String, offset: Vector2, size: Vector2, font_size: int) -> void:
	var button := Button.new()
	button.name = caption
	button.text = caption
	button.size = size
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.055, 0.085, 0.105, 0.78)
	normal.border_color = Color(0.72, 0.82, 0.88, 0.9)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(15)
	button.add_theme_stylebox_override("normal", normal)
	var pressed_style := normal.duplicate()
	pressed_style.bg_color = Color(0.22, 0.39, 0.48, 0.96)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("hover", normal)
	root.add_child(button)
	button.button_down.connect(func(): _button_action(action, true))
	button.button_up.connect(func(): _button_action(action, false))

func _button_action(action: String, pressed: bool) -> void:
	if not is_instance_valid(player): return
	match action:
		"fire": player.set_fire(pressed)
		"aim": player.set_aim(pressed)
		"sprint": player.set_sprint(pressed)
		"reload":
			if pressed: player.reload()
		"jump":
			if pressed: player.request_jump()

func _input(event: InputEvent) -> void:
	if not is_instance_valid(player): return
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < screen_size.x * 0.43 and event.position.y > screen_size.y * 0.55 and joystick_touch == -1:
				joystick_touch = event.index
				_update_joystick(event.position)
			elif event.position.x >= screen_size.x * 0.43 and event.position.y < screen_size.y * LOOK_ZONE_BOTTOM and look_touch == -1 and not _touch_over_button(event.position):
				look_touch = event.index
		else:
			if event.index == joystick_touch:
				joystick_touch = -1
				move_state = Vector2.ZERO
				smoothed_joystick = Vector2.ZERO
				player.set_move(Vector2.ZERO)
				joystick_knob.position = joystick_center - joystick_knob.size * 0.5
			if event.index == look_touch: look_touch = -1
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch:
			_update_joystick(event.position)
		elif event.index == look_touch:
			player.apply_look(event.relative * 0.72)

func _touch_over_button(pos: Vector2) -> bool:
	for child in root.get_children():
		if child is Button and child.get_global_rect().has_point(pos):
			return true
	return false

func _update_joystick(pos: Vector2) -> void:
	var delta := pos - joystick_center
	if delta.length() < 8.0:
		delta = Vector2.ZERO
	else:
		delta = delta.limit_length(JOY_RADIUS)
	joystick_knob.position = joystick_center + delta - joystick_knob.size * 0.5
	var raw := delta / JOY_RADIUS
	if raw.length() < 0.12: raw = Vector2.ZERO
	else: raw = raw.normalized() * inverse_lerp(0.12, 1.0, minf(raw.length(), 1.0))
	smoothed_joystick = smoothed_joystick.lerp(raw, 0.42)
	move_state = smoothed_joystick
	player.set_move(move_state)

func set_health(value: float) -> void:
	if is_instance_valid(health_label):
		health_label.text = "HEALTH %03d" % int(value)
		health_bar.value = value

func set_ammo(current: int, reserve: int) -> void:
	if is_instance_valid(ammo_label): ammo_label.text = "%02d / %03d" % [current, reserve]

func set_objective(value: String) -> void:
	if is_instance_valid(objective_label): objective_label.text = value
