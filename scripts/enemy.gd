extends CharacterBody3D
var target: Node3D
var enemy_id := 0
var health := 100.0
var attack_timer := 0.0
var body_mesh: MeshInstance3D

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
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	head.mesh = sphere
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.24,0.19,0.14)
	head.material_override = head_mat
	head.position.y = 1.82
	add_child(head)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target): return
	attack_timer = maxf(0,attack_timer-delta)
	var to_target: Vector3 = target.global_position-global_position
	to_target.y = 0
	var distance := to_target.length()
	if distance > 2.8 and distance < 42:
		var dir := to_target.normalized()
		velocity.x = dir.x*2.0
		velocity.z = dir.z*2.0
		look_at(Vector3(target.global_position.x,global_position.y,target.global_position.z),Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x,0,5*delta)
		velocity.z = move_toward(velocity.z,0,5*delta)
	if not is_on_floor(): velocity.y -= 9.8*delta
	move_and_slide()
	if distance < 24 and attack_timer <= 0:
		attack_timer = 1.15
		if target.has_method("take_damage"): target.take_damage(6.0)

func take_hit(amount: float) -> void:
	health -= amount
	if health <= 0:
		if target and target.has_signal("enemy_killed"): target.enemy_killed.emit()
		queue_free()
	else:
		var mat := body_mesh.material_override as StandardMaterial3D
		mat.albedo_color = Color(0.42,0.12,0.1)
		get_tree().create_timer(0.12).timeout.connect(func():
			if is_instance_valid(body_mesh): mat.albedo_color = Color(0.12,0.16,0.13)
		)
