extends Node3D
const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const HudScript = preload("res://scripts/hud.gd")
var player
var hud
var enemies_remaining := 0

func _ready() -> void:
	_setup_world()
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.name = "Player"
	add_child(player)
	player.position = Vector3(0, 0, 10)
	player.health_changed.connect(_on_health_changed)
	player.ammo_changed.connect(_on_ammo_changed)
	player.enemy_killed.connect(_on_enemy_killed)
	player.hit_confirmed.connect(_on_hit_confirmed)
	hud = CanvasLayer.new()
	hud.set_script(HudScript)
	add_child(hud)
	hud.set_player(player)
	_spawn_enemies()
	hud.set_objective("ELIMINATE HOSTILE FORCES  •  %d REMAINING" % enemies_remaining)

func _setup_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.025, 0.045, 0.075)
	sky_mat.sky_horizon_color = Color(0.22, 0.24, 0.25)
	sky_mat.ground_bottom_color = Color(0.035, 0.04, 0.035)
	sky_mat.ground_horizon_color = Color(0.16, 0.17, 0.15)
	env.sky.sky_material = sky_mat
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.48, 0.52, 0.58)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -28, 0)
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	add_child(sun)
	_make_box(Vector3(0, -0.35, 0), Vector3(90, 0.5, 90), Color(0.19, 0.2, 0.18))
	for i in range(12):
		var x := -24.0 + float(i) * 4.4
		_make_box(Vector3(x, 1.5, -28), Vector3(0.35, 3, 0.35), Color(0.12, 0.14, 0.15))
		_make_box(Vector3(x, 1.5, 28), Vector3(0.35, 3, 0.35), Color(0.12, 0.14, 0.15))
	for i in range(8):
		var z := -22.0 + float(i) * 6.2
		_make_box(Vector3(-27, 1.5, z), Vector3(0.35, 3, 0.35), Color(0.12, 0.14, 0.15))
		_make_box(Vector3(27, 1.5, z), Vector3(0.35, 3, 0.35), Color(0.12, 0.14, 0.15))
	var rng := RandomNumberGenerator.new()
	rng.seed = 2031
	for i in range(22):
		var px := rng.randf_range(-21, 21)
		var pz := rng.randf_range(-20, 20)
		if abs(px) < 5 and pz > 4: continue
		var size := Vector3(rng.randf_range(1.5, 3.4), rng.randf_range(0.8, 1.7), rng.randf_range(1.2, 2.8))
		_make_box(Vector3(px, size.y * 0.5, pz), size, Color(0.16, 0.18, 0.17))
	_make_box(Vector3(-15, 1.35, -10), Vector3(7, 2.7, 3), Color(0.22, 0.12, 0.09))
	_make_box(Vector3(14, 1.35, -16), Vector3(7, 2.7, 3), Color(0.1, 0.17, 0.19))
	_make_box(Vector3(17, 1.35, 12), Vector3(7, 2.7, 3), Color(0.22, 0.16, 0.08))

func _make_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	mesh.material_override = mat
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _spawn_enemies() -> void:
	var positions := [Vector3(-16,0,-18), Vector3(12,0,-22), Vector3(20,0,-3), Vector3(-20,0,9), Vector3(9,0,17), Vector3(-8,0,-2)]
	for i in range(positions.size()):
		var enemy := CharacterBody3D.new()
		enemy.set_script(EnemyScript)
		enemy.name = "Hostile_%02d" % (i + 1)
		enemy.position = positions[i]
		enemy.target = player
		enemy.enemy_id = i + 1
		add_child(enemy)
	enemies_remaining = positions.size()

func _on_health_changed(value: float) -> void: hud.set_health(value)
func _on_ammo_changed(current: int, reserve: int) -> void: hud.set_ammo(current, reserve)
func _on_enemy_killed() -> void:
	enemies_remaining = maxi(0, enemies_remaining - 1)
	if enemies_remaining == 0:
		hud.set_objective("MISSION COMPLETE  •  AREA SECURE")
	else:
		hud.set_objective("ELIMINATE HOSTILE FORCES  •  %d REMAINING" % enemies_remaining)

func _on_hit_confirmed() -> void:
	if is_instance_valid(hud): hud.show_hit_confirm()
