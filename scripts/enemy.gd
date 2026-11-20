extends CharacterBody3D

var target: Node3D
var enemy_id := 0
var health := 100.0
var attack_timer := 0.0
var patrol_origin := Vector3.ZERO
var patrol_initialized := false
var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var alert_level := 0.0
const DETECT_RANGE := 32.0
const ATTACK_RANGE := 19.0
const PATROL_SPEED := 1.15
const CHASE_SPEED := 2.35

func _ready() -> void:
	add_to_group("enemies")
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.75
	var col := CollisionShape3D.new()
	col.shape = capsule
	col.position.y = 0.88
	add_child(col)
	body_mesh = MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.36
	mesh.height = 1.7
	body_mesh.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12,0.16,0.13)
	mat.roughness = 0.95
	body_mesh.material_override = mat
	body_mesh.position.y = 0.9
	add_child(body_mesh)
	head_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	head_mesh.mesh = sphere
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.24,0.19,0.14)
	head_mesh.material_override = head_mat
	head_mesh.position.y = 1.82
	add_child(head_mesh)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target): return
	if not patrol_initialized:
		patrol_origin = global_position
		patrol_initialized = true
	attack_timer = maxf(0.0, attack_timer - delta)
	var to_target := target.global_position - global_position
	var flat_to_target := Vector3(to_target.x, 0.0, to_target.z)
	var distance := flat_to_target.length()
	var can_see := distance <= DETECT_RANGE and _has_line_of_sight()
	var move_direction := Vector3.ZERO
	var move_speed := PATROL_SPEED

	if can_see:
		alert_level = minf(1.0, alert_level + delta * 2.5)
		if distance > 7.0:
			move_direction = flat_to_target.normalized()
			move_speed = CHASE_SPEED
		if distance < ATTACK_RANGE and attack_timer <= 0.0:
			attack_timer = 1.35
			if target.has_method("take_damage"):
				target.take_damage(5.0)
	else:
		alert_level = maxf(0.0, alert_level - delta * 0.4)
		var t := float(Time.get_ticks_msec()) * 0.00035 + float(enemy_id) * 1.7
		var patrol_point := patrol_origin + Vector3(cos(t) * 3.0, 0.0, sin(t) * 3.0)
		var to_patrol := patrol_point - global_position
		to_patrol.y = 0.0
		if to_patrol.length() > 0.35:
			move_direction = to_patrol.normalized()

	if move_direction.length() > 0.05:
		var desired := move_direction * move_speed
		velocity.x = move_toward(velocity.x, desired.x, 7.0 * delta)
		velocity.z = move_toward(velocity.z, desired.z, 7.0 * delta)
		var look_point := global_position + move_direction
		look_at(Vector3(look_point.x, global_position.y, look_point.z), Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)

	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _has_line_of_sight() -> bool:
	if not is_instance_valid(target): return false
	var from := global_position + Vector3.UP * 1.45
	var to := target.global_position + Vector3.UP * 1.2
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == target

func take_hit(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		if target and target.has_signal("enemy_killed"):
			target.enemy_killed.emit()
		queue_free()
	else:
		var mat := body_mesh.material_override as StandardMaterial3D
		mat.albedo_color = Color(0.55, 0.12, 0.09)
		get_tree().create_timer(0.14).timeout.connect(func():
			if is_instance_valid(body_mesh):
				mat.albedo_color = Color(0.12, 0.16, 0.13)
		)
