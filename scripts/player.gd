extends CharacterBody3D
signal health_changed(value: float)
signal ammo_changed(current: int, reserve: int)
signal enemy_killed
signal hit_confirmed
const SPEED := 5.4
const SPRINT_SPEED := 8.0
const MOUSE_SENS := 0.0022
const MAG_SIZE := 30
var health := 100.0
var ammo := MAG_SIZE
var reserve_ammo := 120
var reloading := false
var fire_cooldown := 0.0
var reload_timer := 0.0
var pitch := 0.0
var virtual_move := Vector2.ZERO
var virtual_fire := false
var virtual_sprint := false
var aiming := false
var smoothed_move := Vector2.ZERO
var jump_requested := false
var recoil_pitch := 0.0
var weapon_kick := 0.0
var sway_time := 0.0
const MOVE_RESPONSE := 11.0
const STOP_RESPONSE := 15.0
var camera: Camera3D
var weapon_root: Node3D
var muzzle_flash: OmniLight3D

func _ready() -> void:
	_configure_input()
	add_to_group("player")
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	var col := CollisionShape3D.new()
	col.shape = capsule
	col.position.y = 0.9
	add_child(col)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.55, 0)
	camera.current = true
	camera.fov = 78
	add_child(camera)
	_build_weapon()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_changed.emit(health)
	ammo_changed.emit(ammo, reserve_ammo)

func _configure_input() -> void:
	var bindings := {"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D, "sprint": KEY_SHIFT, "jump": KEY_SPACE, "reload": KEY_R}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var key_event := InputEventKey.new()
		key_event.physical_keycode = bindings[action]
		InputMap.action_add_event(action, key_event)

func _build_weapon() -> void:
	weapon_root = Node3D.new()
	weapon_root.position = Vector3(0.28, -0.25, -0.52)
	camera.add_child(weapon_root)
	_add_weapon_box(Vector3.ZERO, Vector3(0.16,0.18,0.62), Color(0.075,0.085,0.09))
	_add_weapon_box(Vector3(0,-0.13,-0.08), Vector3(0.12,0.23,0.16), Color(0.12,0.1,0.08))
	_add_weapon_box(Vector3(0,0.1,-0.15), Vector3(0.1,0.06,0.24), Color(0.035,0.04,0.045))
	var barrel := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.025
	cylinder.bottom_radius = 0.025
	cylinder.height = 0.48
	barrel.mesh = cylinder
	barrel.rotation.x = PI / 2
	barrel.position.z = -0.48
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.045,0.05,0.055)
	barrel.material_override = mat
	weapon_root.add_child(barrel)
	muzzle_flash = OmniLight3D.new()
	muzzle_flash.light_color = Color(1,0.58,0.18)
	muzzle_flash.light_energy = 2.5
	muzzle_flash.omni_range = 3
	muzzle_flash.visible = false
	muzzle_flash.position.z = -0.72
	weapon_root.add_child(muzzle_flash)

func _add_weapon_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.55
	mat.roughness = 0.48
	mesh.material_override = mat
	mesh.position = pos
	weapon_root.add_child(mesh)

func _unhandled_input(event: InputEvent) -> void:
	# Android can synthesize mouse-button events from ordinary screen taps.
	# Never interpret those events as firing: mobile firing is owned only by the FIRE HUD button.
	var is_mobile := OS.get_name() == "Android" or OS.get_name() == "iOS"
	if not is_mobile:
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			apply_look(event.relative)
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT: virtual_fire = true
			elif event.button_index == MOUSE_BUTTON_RIGHT: aiming = true
		if event is InputEventMouseButton and not event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT: virtual_fire = false
			elif event.button_index == MOUSE_BUTTON_RIGHT: aiming = false
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func apply_look(delta: Vector2) -> void:
	rotate_y(-delta.x * MOUSE_SENS)
	pitch = clampf(pitch - delta.y * MOUSE_SENS, deg_to_rad(-80), deg_to_rad(80))
	camera.rotation.x = pitch + recoil_pitch
func set_move(value: Vector2) -> void: virtual_move = value.limit_length(1.0)
func request_jump() -> void: jump_requested = true
func set_fire(value: bool) -> void: virtual_fire = value
func set_aim(value: bool) -> void: aiming = value
func set_sprint(value: bool) -> void: virtual_sprint = value

func _physics_process(delta: float) -> void:
	fire_cooldown = maxf(0, fire_cooldown - delta)
	if reloading:
		reload_timer -= delta
		if reload_timer <= 0:
			var loaded := mini(MAG_SIZE - ammo, reserve_ammo)
			ammo += loaded
			reserve_ammo -= loaded
			reloading = false
			ammo_changed.emit(ammo, reserve_ammo)
	var keyboard_vec := Input.get_vector("move_left","move_right","move_forward","move_back")
	var target_move := virtual_move if virtual_move.length() > 0.02 else keyboard_vec
	var response := MOVE_RESPONSE if target_move.length() > 0.02 else STOP_RESPONSE
	smoothed_move = smoothed_move.move_toward(target_move, response * delta)
	var direction := (transform.basis * Vector3(smoothed_move.x,0,smoothed_move.y)).normalized()
	var speed := SPRINT_SPEED if (Input.is_action_pressed("sprint") or virtual_sprint) and not aiming else SPEED
	var target_x := direction.x * speed
	var target_z := direction.z * speed
	var acceleration := 22.0 if target_move.length() > 0.02 else 27.0
	velocity.x = move_toward(velocity.x, target_x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_z, acceleration * delta)
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	elif Input.is_action_just_pressed("jump") or jump_requested:
		velocity.y = 4.5
	jump_requested = false
	move_and_slide()
	camera.fov = lerpf(camera.fov, 58.0 if aiming else 78.0, delta * 8.0)
	recoil_pitch = lerpf(recoil_pitch, 0.0, delta * 9.0)
	camera.rotation.x = pitch + recoil_pitch
	weapon_kick = lerpf(weapon_kick, 0.0, delta * 13.0)
	sway_time += delta * (smoothed_move.length() * 8.0)
	var bob := Vector3(sin(sway_time) * 0.012, absf(cos(sway_time)) * 0.012, 0.0) if smoothed_move.length() > 0.08 else Vector3.ZERO
	var target_weapon_pos := Vector3(0.18 if aiming else 0.28, -0.25, -0.52 + weapon_kick) + bob
	weapon_root.position = weapon_root.position.lerp(target_weapon_pos, delta * 10.0)
	if virtual_fire: _fire()
	elif not (OS.get_name() == "Android" or OS.get_name() == "iOS") and Input.is_action_pressed("fire"): _fire()
	if Input.is_action_just_pressed("reload"): reload()

func _fire() -> void:
	if fire_cooldown > 0 or reloading: return
	if ammo <= 0:
		reload()
		return
	fire_cooldown = 0.105
	ammo -= 1
	ammo_changed.emit(ammo,reserve_ammo)
	muzzle_flash.visible = true
	get_tree().create_timer(0.045).timeout.connect(func(): muzzle_flash.visible = false)
	var origin := camera.global_position
	var direction := -camera.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(origin,origin+direction*100.0)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit and hit.collider.is_in_group("enemies"):
		hit.collider.take_hit(34.0)
		hit_confirmed.emit()
	recoil_pitch = minf(recoil_pitch + deg_to_rad(0.48 if aiming else 0.72), deg_to_rad(4.0))
	weapon_kick = 0.13

func reload() -> void:
	if reloading or ammo == MAG_SIZE or reserve_ammo <= 0: return
	reloading = true
	reload_timer = 1.65

func take_damage(amount: float) -> void:
	health = maxf(0,health-amount)
	health_changed.emit(health)
	if health <= 0:
		health = 100
		global_position = Vector3(0,1.2,10)
		health_changed.emit(health)
