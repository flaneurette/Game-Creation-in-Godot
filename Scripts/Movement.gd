extends CharacterBody3D

const WALK_SPEED = 5.0
const RUN_SPEED = 9.0
const CROUCH_SPEED = 2.5
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003

const STAND_HEIGHT = 1.8
const CROUCH_HEIGHT = 1.0
const CROUCH_LERP_SPEED = 10.0

@onready var camera: Camera3D = $Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D2

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_crouching = false
var standing_camera_y: float

# type must match GameManager's resource names exactly.
# range: how far the raycast reaches. splash_radius: 0 = single-target hit,
# >0 = also damages everything with take_damage() within that radius of the hit point.
var weapons = [
	{"type": "gun",       "damage": 25.0,  "range": 100.0, "splash_radius": 0.0},
	{"type": "explosives", "damage": 100.0, "range": 100.0, "splash_radius": 4.0},
	{"type": "knife",      "damage": 15.0, "range": 2.5,   "splash_radius": 0.0},
]
# -1 = unarmed; the first Tab press equips the first weapon.
var current_weapon_index = -1

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	standing_camera_y = camera.position.y
	_update_ammo_hud()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if event.is_action_pressed("shoot"):
		shoot()

	if event.is_action_pressed("weapon_switch"):
		switch_weapon()

	if event.is_action_pressed("interact"):
		_try_talk()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY

	handle_crouch(delta)

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var speed = WALK_SPEED
	if is_crouching:
		speed = CROUCH_SPEED
	elif Input.is_action_pressed("sprint"):
		speed = RUN_SPEED

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, WALK_SPEED)

	move_and_slide()

func handle_crouch(delta):
	is_crouching = Input.is_action_pressed("crouch")

	var target_height = CROUCH_HEIGHT if is_crouching else STAND_HEIGHT
	var target_camera_y = standing_camera_y - (STAND_HEIGHT - target_height)

	if collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = move_toward(collision_shape.shape.height, target_height, CROUCH_LERP_SPEED * delta)
		collision_shape.position.y = collision_shape.shape.height / 2.0

	camera.position.y = move_toward(camera.position.y, target_camera_y, CROUCH_LERP_SPEED * delta)

func switch_weapon() -> void:
	current_weapon_index = (current_weapon_index + 1) % weapons.size()
	var weapon = weapons[current_weapon_index]
	print("Switched to: ", weapon.type)
	_update_ammo_hud()
	EventBus.weapon_switched.emit(weapon.type)

func shoot() -> void:
	if current_weapon_index < 0:
		print("No weapon equipped - press Tab.")
		return
	var weapon = weapons[current_weapon_index]

	if not GameManager.hasAmmo(weapon.type):
		print("Out of ", weapon.type, "!")
		return

	var space_state = get_world_3d().direct_space_state
	var ray_origin = camera.global_transform.origin
	var ray_end = ray_origin - camera.global_transform.basis.z * weapon.range
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = space_state.intersect_ray(query)

	EventBus.weapon_fired.emit(camera.global_transform.origin, weapon.type)
	GameManager.weaponUsed(weapon.type)
	_update_ammo_hud()
	print("Weapon used: ", weapon.type)

	if not result:
		return

	var hit_object = result.collider
	print("Hit: ", hit_object.name)
	print("Hit at position: ", result.position)
	print("Hit normal: ", result.normal)

	if hit_object.is_in_group("enemies"):
		print("Hit an enemy!")

	if weapon.splash_radius > 0.0:
		_apply_splash_damage(result.position, weapon.damage, weapon.splash_radius)
	elif hit_object.has_method("take_damage"):
		hit_object.take_damage(weapon.damage, self)

func _apply_splash_damage(center: Vector3, damage: float, radius: float) -> void:
	var space_state = get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = radius

	var shape_query = PhysicsShapeQueryParameters3D.new()
	shape_query.shape = shape
	shape_query.transform = Transform3D(Basis(), center)
	shape_query.collide_with_bodies = true

	var hits = space_state.intersect_shape(shape_query, 32)
	for hit in hits:
		var body = hit.collider
		if body.has_method("take_damage"):
			# Simple linear falloff by distance from blast center.
			var dist = center.distance_to(body.global_transform.origin)
			var falloff = clamp(1.0 - (dist / radius), 0.0, 1.0)
			body.take_damage(damage * falloff, self)

func _try_talk() -> void:
	var space_state = get_world_3d().direct_space_state
	var ray_origin = camera.global_transform.origin
	var ray_end = ray_origin - camera.global_transform.basis.z * 3.0  # short interact range
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = space_state.intersect_ray(query)

	if result and result.collider.has_method("talk_to"):
		result.collider.talk_to(self)

func _update_ammo_hud() -> void:
	if current_weapon_index < 0:
		EventBus.player_ammo_changed.emit(0, 0)
		return
	var weapon = weapons[current_weapon_index]
	EventBus.player_ammo_changed.emit(GameManager.getAmmoCount(weapon.type), GameManager.getMaxAmmo(weapon.type))
