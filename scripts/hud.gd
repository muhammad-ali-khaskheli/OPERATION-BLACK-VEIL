extends CanvasLayer
var player
var health_label: Label
var ammo_label: Label
var objective_label: Label
var health_bar: ProgressBar
var move_state := Vector2.ZERO

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)
	objective_label = Label.new()
	objective_label.position = Vector2(24,20)
	objective_label.add_theme_font_size_override("font_size",19)
	objective_label.add_theme_color_override("font_color",Color(0.9,0.83,0.65))
	root.add_child(objective_label)
	health_label = Label.new()
	health_label.position = Vector2(24,56)
	health_label.text = "HEALTH 100"
	health_label.add_theme_font_size_override("font_size",17)
	root.add_child(health_label)
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(24,84)
	health_bar.size = Vector2(190,12)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	root.add_child(health_bar)
	ammo_label = Label.new()
	ammo_label.anchor_left = 1
	ammo_label.anchor_top = 1
	ammo_label.anchor_right = 1
	ammo_label.anchor_bottom = 1
	ammo_label.offset_left = -220
	ammo_label.offset_top = -74
	ammo_label.offset_right = -24
	ammo_label.offset_bottom = -34
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_label.add_theme_font_size_override("font_size",25)
	root.add_child(ammo_label)
	_add_button(root,"FIRE",Vector2(-120,-150),Vector2(100,64),"fire")
	_add_button(root,"RELOAD",Vector2(-240,-80),Vector2(105,48),"reload")
	_add_button(root,"AIM",Vector2(-240,-140),Vector2(90,48),"aim")
	_add_button(root,"UP",Vector2(105,-160),Vector2(64,48),"forward")
	_add_button(root,"DOWN",Vector2(105,-55),Vector2(64,48),"back")
	_add_button(root,"LEFT",Vector2(35,-108),Vector2(64,48),"left")
	_add_button(root,"RIGHT",Vector2(175,-108),Vector2(64,48),"right")
	_add_button(root,"SPRINT",Vector2(250,-62),Vector2(88,46),"sprint")
	_add_button(root,"JUMP",Vector2(-120,-78),Vector2(90,48),"jump")
	ammo_label.text = "30 / 120"

func set_player(value) -> void: player = value
func _add_button(parent: Control, caption: String, offset: Vector2, size: Vector2, action: String) -> void:
	var button := Button.new()
	button.text = caption
	button.size = size
	button.anchor_left = 1 if offset.x < 0 else 0
	button.anchor_right = button.anchor_left
	button.anchor_top = 1
	button.anchor_bottom = 1
	button.position = offset
	button.add_theme_font_size_override("font_size",13)
	button.modulate = Color(1,1,1,0.82)
	parent.add_child(button)
	button.button_down.connect(func(): _button_action(action,true))
	button.button_up.connect(func(): _button_action(action,false))

func _button_action(action: String, pressed: bool) -> void:
	if not is_instance_valid(player): return
	match action:
		"fire": player.set_fire(pressed)
		"aim": player.set_aim(pressed)
		"sprint": player.set_sprint(pressed)
		"reload":
			if pressed: player.reload()
		"jump":
			if pressed: player.velocity.y = 4.5
		"forward": move_state.y = -1 if pressed else 0
		"back": move_state.y = 1 if pressed else 0
		"left": move_state.x = -1 if pressed else 0
		"right": move_state.x = 1 if pressed else 0
	player.set_move(move_state)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag and event.position.x > get_viewport().get_visible_rect().size.x*0.42:
		if is_instance_valid(player): player.apply_look(event.relative*1.5)

func set_health(value: float) -> void:
	if is_instance_valid(health_label):
		health_label.text = "HEALTH %03d" % int(value)
		health_bar.value = value
func set_ammo(current: int,reserve: int) -> void:
	if is_instance_valid(ammo_label): ammo_label.text = "%02d / %03d" % [current,reserve]
func set_objective(value: String) -> void:
	if is_instance_valid(objective_label): objective_label.text = value
