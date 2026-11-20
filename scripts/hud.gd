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
var screen_size := Vector2.ZERO

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
	_reposition_joystick()

func _build_hud() -> void:
	objective_label = Label.new()
	objective_label.position = Vector2(24, 18)
	objective_label.add_theme_font_size_override("font_size", 20)
	objective_label.add_theme_color_override("font_color", Color(0.94, 0.86, 0.68))
	root.add_child(objective_label)

	health_label = Label.new()
	health_label.position = Vector2(24, 50)
	health_label.text = "HEALTH 100"
	health_label.add_theme_font_size_override("font_size", 17)
	root.add_child(health_label)

	health_bar = ProgressBar.new()
	health_bar.position = Vector2(24, 78)
	health_bar.size = Vector2(190, 12)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	root.add_child(health_bar)

	ammo_label = Label.new()
	ammo_label.anchor_left = 1
	ammo_label.anchor_right = 1
	ammo_label.anchor_top = 1
	ammo_label.anchor_bottom = 1
	ammo_label.offset_left = -210
	ammo_label.offset_top = -56
	ammo_label.offset_right = -24
	ammo_label.offset_bottom = -20
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_label.add_theme_font_size_override("font_size", 24)
	root.add_child(ammo_label)
	ammo_label.text = "30 / 120"

	_create_joystick()
	_add_button("FIRE", Vector2(-122, -124), Vector2(104, 82), "fire", 20)
	_add_button("AIM", Vector2(-238, -112), Vector2(94, 62), "aim", 16)
	_add_button("RELOAD", Vector2(-238, -42), Vector2(94, 52), "reload", 14)
	_add_button("JUMP", Vector2(-350, -42), Vector2(92, 52), "jump", 14)
	_add_button("SPRINT", Vector2(202, -64), Vector2(94, 54), "sprint", 14)

func _create_joystick() -> void:
	joystick_base = Panel.new()
	joystick_base.size = Vector2(154, 154)
	joystick_base.anchor_left = 0
	joystick_base.anchor_right = 0
	joystick_base.anchor_top = 1
	joystick_base.anchor_bottom = 1
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(0.08, 0.10, 0.12, 0.48)
	base_style.border_color = Color(0.8, 0.84, 0.86, 0.55)
	base_style.set_border_width_all(2)
	base_style.set_corner_radius_all(77)
	joystick_base.add_theme_stylebox_override("panel", base_style)
	root.add_child(joystick_base)

	joystick_knob = Panel.new()
	joystick_knob.size = Vector2(66, 66)
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.72, 0.78, 0.8, 0.62)
	knob_style.border_color = Color(1, 1, 1, 0.72)
	knob_style.set_border_width_all(2)
	knob_style.set_corner_radius_all(33)
	joystick_knob.add_theme_stylebox_override("panel", knob_style)
	root.add_child(joystick_knob)
	_reposition_joystick()

func _reposition_joystick() -> void:
	if not is_instance_valid(joystick_base): return
	joystick_base.position = Vector2(28, -178)
	joystick_knob.position = joystick_base.position + Vector2(44, 44)

func _add_button(caption: String, offset: Vector2, size: Vector2, action: String, font_size: int) -> void:
	var button := Button.new()
	button.text = caption
	button.size = size
	button.anchor_left = 1
	button.anchor_right = 1
	button.anchor_top = 1
	button.anchor_bottom = 1
	button.position = offset
	button.add_theme_font_size_override("font_size", font_size)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.15, 0.72)
	style.border_color = Color(0.72, 0.78, 0.8, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	button.add_theme_stylebox_override("normal", style)
	var pressed_style := style.duplicate()
	pressed_style.bg_color = Color(0.28, 0.36, 0.39, 0.92)
	button.add_theme_stylebox_override("pressed", pressed_style)
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
			if pressed and player.is_on_floor(): player.velocity.y = 4.5

func _input(event: InputEvent) -> void:
	if not is_instance_valid(player): return
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < screen_size.x * 0.43 and event.position.y > screen_size.y * 0.48 and joystick_touch == -1:
				joystick_touch = event.index
				joystick_center = joystick_base.global_position + joystick_base.size * 0.5
				_update_joystick(event.position)
			elif event.position.x >= screen_size.x * 0.43 and event.position.y < screen_size.y * 0.76 and look_touch == -1:
				look_touch = event.index
		else:
			if event.index == joystick_touch:
				joystick_touch = -1
				move_state = Vector2.ZERO
				player.set_move(move_state)
				joystick_knob.position = joystick_base.position + Vector2(44, 44)
			if event.index == look_touch: look_touch = -1
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch:
			_update_joystick(event.position)
		elif event.index == look_touch:
			player.apply_look(event.relative * 0.42)
	elif event is InputEventMouseMotion and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			player.apply_look(event.relative * 0.002)

func _update_joystick(pos: Vector2) -> void:
	var delta := pos - joystick_center
	if delta.length() > 58: delta = delta.normalized() * 58
	joystick_knob.position = joystick_base.position + joystick_base.size * 0.5 + delta - joystick_knob.size * 0.5
	move_state = Vector2(delta.x / 58.0, delta.y / 58.0)
	player.set_move(move_state)

func set_health(value: float) -> void:
	if is_instance_valid(health_label):
		health_label.text = "HEALTH %03d" % int(value)
		health_bar.value = value

func set_ammo(current: int, reserve: int) -> void:
	if is_instance_valid(ammo_label): ammo_label.text = "%02d / %03d" % [current, reserve]

func set_objective(value: String) -> void:
	if is_instance_valid(objective_label): objective_label.text = value
