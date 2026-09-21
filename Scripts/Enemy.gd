class_name Enemy
extends CharacterBody3D

enum State { PATROL, SUSPICIOUS, CHASE }

@export_group("Stats")
@export var max_health: float = 100.0
@export var contact_damage: float = 30.0
@export_group("Shooting")
# While chasing, the enemy fires this often (seconds) at the player.
@export var shoot_interval: float = 1.0
@export var shoot_damage: int = 10
@export var shoot_range: float = 30.0
# Chance each shot hits (0 = always misses, 1 = never misses).
@export_range(0.0, 1.0) var hit_chance: float = 0.6
@export_group("Movement")
@export var move_speed: float = 3
@export var anim_walk_speed_reference: float = 1.5
@export var anim_run_speed_reference: float = 4.5
@export var chase_speed: float = 4.5
@export var attack_range: float = 1.5
# How fast the body can swing to a new heading. A rate cap absorbs corner
# noise *and* stays smooth, where a dot-product deadzone just quantises the
# turn into visible snaps.
@export var turn_speed_deg: float = 540.0
# Linear accel/decel in m/s^2. Stops velocity (and therefore the animation
# speed) from changing discontinuously at waypoints.
@export var accel: float = 14.0
@export_group("Navigation")
# How close to a path waypoint counts as reaching it.
@export var path_desired_distance: float = 0.5
@export var target_desired_distance: float = 0.8
# The navmesh is baked on the floor but the body origin sits at the capsule's
# centre, so the agent's 3D distance check never clears and it orbits
# waypoints forever. This drives the waypoint's y onto the body's y at
# runtime — no sign guessing, and it tracks ramps and stairs automatically.
@export var auto_calibrate_path_height: bool = true
@export_group("Patrol")
# Keep sampling until we find a point at least this far away, measured
# ALONG THE PATH rather than as the crow flies.
@export var min_patrol_distance: float = 14.0
# 0 = no upper limit. On a large open navmesh, leaving this at 0 produces
# 300m+ legs and minutes of walking.
@export var max_patrol_distance: float = 60.0
@export var patrol_point_attempts: int = 16
# 0 = every layer. _resolve_sampling_layers() falls back to all layers if
# this mask matches no region on the map.
@export_flags_3d_navigation var patrol_navigation_layers: int = 0
# Random pause on arrival before heading somewhere new.
@export var patrol_dwell_range: Vector2 = Vector2(0.5, 2.5)
@export_group("Behaviour")
@export var suspicion_duration: float = 5.0
@export_group("Animation")
# Ground speed the walk/run clip was authored at, in METRES PER SECOND.
# (A frame rate like 60 here makes speed_scale ~0.05 — a frozen animation.)
@export var anim_speed_scale_min: float = 0.3
@export var anim_speed_scale_max: float = 2.0
# Below this the character is considered stopped (animation pauses).
@export var anim_move_threshold: float = 0.15
@export_group("Debug")
@export var debug_patrol: bool = false
@export var debug_live: bool = false
@export var debug_targets: bool = false
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
# @onready var anim_player: AnimationPlayer = $"Walking/Animation/"
@onready var anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false)
@export var anim_name: StringName = &"Animations/Walking"
@export var anim_run_name: StringName = &"Animations/Pistol Run"
@export var anim_idle_name: StringName = &"Animations/Neutral Idle"
@export var anim_death_name: StringName = &"Animations/Falling Back Death"

var current_health: float
var state: State = State.PATROL
var player_ref: Node3D = null

var suspicion_timer: float = 0.0
var chase_target_update_timer: float = 0.0
# Counts down while chasing; the enemy shoots when it reaches 0.
var shoot_timer: float = 1.0
var patrol_dwell_timer: float = 0.0
# Safety net: if we somehow never register an arrival, move on anyway.
var patrol_timeout: float = 0.0
# target_position is processed on the next navigation sync, so for a frame
# after setting it the agent still describes the OLD, completed path.
var patrol_path_settle: int = 0
# True once a patrol target has been committed. Until then the agent still
# holds its default target of (0, 0, 0) and must not be driven.
var has_patrol_target: bool = false

# Resolved once the map has synced — see _resolve_sampling_layers().
var sample_layers: int = 0xFFFFFFFF

# The single source of truth for which way we face. Movement, rotation and
# the animation all read from this, so they can never disagree with each
# other - disagreement between them is what causes shake and ghosting.
var facing_yaw: float = 0.0
# Low-passed horizontal speed. Drives speed_scale so it never chatters
# around the play/pause threshold.
var anim_speed: float = 0.0

var _debug_timer: float = 0.0


func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")

	facing_yaw = rotation.y

	nav_agent.path_desired_distance = path_desired_distance
	nav_agent.target_desired_distance = target_desired_distance
	nav_agent.avoidance_enabled = false
	nav_agent.path_height_offset = 0.0

	# Smooths out visual stutter on high-refresh displays: the body only moves
	# on physics ticks, so without this you see the steps.
	if "physics_interpolation_mode" in self:
		physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON

	# Make the clips loop so they never stop and get re-triggered.
	if anim_player:
		for n in [anim_name, anim_run_name, anim_idle_name]:
			if anim_player.has_animation(n):
				var clip := anim_player.get_animation(n)
				clip.loop_mode = Animation.LOOP_LINEAR
				_strip_root_motion(clip)
				
	await _await_navigation_ready()
	if not is_inside_tree():
		return

	sample_layers = _resolve_sampling_layers()

	if debug_patrol:
		_debug_navmesh_report()

	_pick_new_patrol_point()
	
# The Mixamo clips aren't "in place": they translate the metarig root forward
# every loop (~16 units for Walking). The body is moved by move_and_slide(),
# so the mesh drifts ahead of it and snaps back when the clip wraps - the
# periodic backwards bump, whatever move_speed is. Pin the root's horizontal
# position to its first key; vertical bob is kept.
func _strip_root_motion(clip: Animation) -> void:
	for i in clip.get_track_count():
		if clip.track_get_type(i) != Animation.TYPE_POSITION_3D:
			continue
		if clip.track_get_path(i) != NodePath("metarig"):
			continue
		var keys := clip.track_get_key_count(i)
		if keys == 0:
			continue
		var origin: Vector3 = clip.track_get_key_value(i, 0)
		for k in keys:
			var v: Vector3 = clip.track_get_key_value(i, k)
			clip.track_set_key_value(i, k, Vector3(origin.x, v.y, origin.z))

# map_get_iteration_id() ticks over to 1 BEFORE the regions' polygons are
# actually merged into the map, so gating on it alone lets _ready() run while
# every query still returns the Vector3.ZERO failure value. The only reliable
# readiness test is the operation we depend on returning a real point.
func _await_navigation_ready(max_frames: int = 600) -> void:
	for frame in max_frames:
		if not is_inside_tree():
			return
		var map_rid := get_world_3d().navigation_map
		if map_rid.is_valid() \
				and NavigationServer3D.map_get_iteration_id(map_rid) > 0 \
				and not NavigationServer3D.map_get_regions(map_rid).is_empty():
			var probe := NavigationServer3D.map_get_random_point(map_rid, 0xFFFFFFFF, true)
			if probe.is_finite() and not probe.is_zero_approx():
				return
		await get_tree().physics_frame
	push_warning("%s: navigation map never became queryable - is there a baked NavigationRegion3D?" % name)

# map_get_random_point silently returns Vector3.ZERO when no region matches
# the layer mask, which reads downstream as "everywhere is unreachable".
# Verify the mask against the regions actually on the map.
func _resolve_sampling_layers() -> int:
	if patrol_navigation_layers == 0:
		return 0xFFFFFFFF

	var map_rid := get_world_3d().navigation_map
	for r in NavigationServer3D.map_get_regions(map_rid):
		if NavigationServer3D.region_get_navigation_layers(r) & patrol_navigation_layers:
			return patrol_navigation_layers

	push_warning("%s: patrol_navigation_layers=%d matches no navigation region; using all layers."
			% [name, patrol_navigation_layers])
	return 0xFFFFFFFF


func _physics_process(delta: float) -> void:
	velocity.y = 0.0  # no gravity for now — stays glued to nav mesh height

	if auto_calibrate_path_height:
		_calibrate_path_height()

	match state:
		State.PATROL:
			_process_patrol(delta)
		State.SUSPICIOUS:
			_process_suspicious(delta)
		State.CHASE:
			_process_chase(delta)

	_update_walk_animation(delta)

	if debug_live:
		_debug_live_readout(delta)

	move_and_slide()
	_clamp_horizontal_speed()


# get_next_path_position() returns the waypoint with path_height_offset
# SUBTRACTED from its y. We want that waypoint level with the body, so the
# agent's 3D distance check behaves like a horizontal one; otherwise a fixed
# vertical gap keeps it above path_desired_distance forever and the agent
# circles the same waypoint. Nudging the offset by the observed error
# converges immediately and needs no assumption about the sign convention.
func _calibrate_path_height() -> void:
	if nav_agent.is_navigation_finished():
		return
	if nav_agent.get_current_navigation_path().is_empty():
		return

	var err := nav_agent.get_next_path_position().y - global_position.y
	if absf(err) > 0.05:
		nav_agent.path_height_offset += err


# move_and_slide() writes the post-collision velocity back, and depenetration
# against a wall can spike it well past our own speed cap — which then feeds
# a wrong speed_scale into the animation.
func _clamp_horizontal_speed() -> void:
	var cap := chase_speed if state == State.CHASE else move_speed
	var horiz := Vector2(velocity.x, velocity.z)
	if horiz.length() > cap * 1.05:
		horiz = horiz.normalized() * cap
		velocity.x = horiz.x
		velocity.z = horiz.y


# ---------------- STATE: PATROL ----------------

func _process_patrol(delta: float) -> void:
	# No target committed yet — stand still rather than walking to (0, 0, 0),
	# which is what the agent defaults to.
	if not has_patrol_target:
		_decelerate(delta)
		_apply_facing()
		patrol_dwell_timer -= delta
		if patrol_dwell_timer <= 0.0:
			_pick_new_patrol_point()
		return

	# Standing around at the end of a leg.
	if patrol_dwell_timer > 0.0:
		patrol_dwell_timer -= delta
		_decelerate(delta)
		_apply_facing()
		if patrol_dwell_timer <= 0.0:
			_pick_new_patrol_point()
		return

	_move_toward_nav_target(move_speed, delta)

	patrol_timeout -= delta
	if patrol_path_settle > 0:
		patrol_path_settle -= 1
		return

	# Horizontal only - a vertical gap between the body origin and the navmesh
	# must not stop us registering an arrival. Arriving is what ends a leg.
	var arrived := _horizontal_distance(global_position, nav_agent.get_final_position()) \
			<= nav_agent.target_desired_distance + 0.5
	if arrived or patrol_timeout <= 0.0:
		if debug_targets and not arrived:
			print("%s: patrol leg timed out" % name)
		patrol_dwell_timer = randf_range(patrol_dwell_range.x, patrol_dwell_range.y)


func _pick_new_patrol_point() -> void:
	var map_rid := get_world_3d().navigation_map
	var best_point := global_position
	var best_length := -1.0
	var tried := 0
	var rejected_unreachable := 0
	var rejected_degenerate := 0

	for attempt in patrol_point_attempts:
		var candidate := NavigationServer3D.map_get_random_point(map_rid, sample_layers, true)
		if not candidate.is_finite() or candidate.is_zero_approx():
			rejected_degenerate += 1
			continue
		tried += 1

		var length := _path_length_to(map_rid, candidate)
		if length < 0.0:
			rejected_unreachable += 1
			continue
		if max_patrol_distance > 0.0 and length > max_patrol_distance:
			continue

		if length > best_length:
			best_length = length
			best_point = candidate
		if length >= min_patrol_distance:
			break

	if best_length < 0.0:
		has_patrol_target = false
		patrol_dwell_timer = 1.0
		if debug_targets:
			print("%s: no patrol point (%d sampled, %d unreachable, %d degenerate) — retry in 1s"
					% [name, tried, rejected_unreachable, rejected_degenerate])
		return

	nav_agent.target_position = best_point
	has_patrol_target = true
	patrol_path_settle = 2
	patrol_timeout = maxf(10.0, (best_length / maxf(move_speed, 0.1)) * 2.5)

	if debug_targets:
		print("%s: new patrol target %s | path %.1fm | timeout %.0fs"
				% [name, best_point, best_length, patrol_timeout])


# Length of the actual navigation path to `to`, or -1.0 if unreachable.
# map_get_path clips to the closest reachable spot, so a final point far
# from what we asked for means we can't actually get there.
func _path_length_to(map_rid: RID, to: Vector3) -> float:
	# Path from our projection onto the mesh, not from our actual origin —
	# the body floats above the navmesh and that offset is pure noise here.
	var origin := NavigationServer3D.map_get_closest_point(map_rid, global_position)
	if origin.is_zero_approx():
		origin = global_position
	var path := NavigationServer3D.map_get_path(map_rid, origin, to, true, sample_layers)
	if path.size() < 2:
		return -1.0
	if _horizontal_distance(path[path.size() - 1], to) > 1.0:
		return -1.0

	var length := 0.0
	for i in range(1, path.size()):
		length += path[i - 1].distance_to(path[i])
	return length


# ---------------- STATE: SUSPICIOUS ----------------

func _process_suspicious(delta: float) -> void:
	_decelerate(delta)

	if is_instance_valid(player_ref):
		_face_position(player_ref.global_position, delta)
	else:
		_apply_facing()

	suspicion_timer -= delta
	if suspicion_timer <= 0.0:
		player_ref = null
		state = State.PATROL
		_pick_new_patrol_point()

# ---------------- STATE: CHASE ----------------

func _process_chase(delta: float) -> void:
	if not is_instance_valid(player_ref):
		player_ref = null
		state = State.PATROL
		_pick_new_patrol_point()
		return

	chase_target_update_timer -= delta
	if chase_target_update_timer <= 0.0:
		nav_agent.target_position = player_ref.global_position
		chase_target_update_timer = 0.25

	var dist_to_player := global_position.distance_to(player_ref.global_position)
	if dist_to_player > attack_range:
		_move_toward_nav_target(chase_speed, delta)
	else:
		_decelerate(delta)
		_face_position(player_ref.global_position, delta)

	# Shoot on a fixed interval while chasing, moving or not.
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = shoot_interval
		if dist_to_player <= shoot_range and _has_line_of_sight(player_ref) \
				and randf() < hit_chance:
			GameManager.damagePlayer(shoot_damage)

func _has_line_of_sight(target: Node3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position, target.global_position)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == target

# ---------------- MOVEMENT ----------------

func _move_toward_nav_target(speed: float, delta: float) -> void:
	if nav_agent.is_navigation_finished():
		_decelerate(delta)
		_apply_facing()
		return

	var next_point := nav_agent.get_next_path_position()
	var to_next := next_point - global_position
	to_next.y = 0.0

	# Only update the *heading* when the waypoint is meaningfully far away;
	# velocity still gets driven below, so we never freeze mid-step.
	if to_next.length() > 0.05:
		_face_position(next_point, delta)
	else:
		_apply_facing()

	var dir := _facing_vector()
	velocity.x = move_toward(velocity.x, dir.x * speed, accel * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, accel * delta)


func _decelerate(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, accel * delta)
	velocity.z = move_toward(velocity.z, 0.0, accel * delta)

# Rotate toward a world position at a bounded angular rate, then write the
# result to rotation.y. No second lerp on top - a smoothed value lerped
# again just lags the body behind its own motion, which reads as sliding.
func _face_position(target: Vector3, delta: float) -> void:
	var to_target := target - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		_apply_facing()
		return

	var target_yaw := atan2(to_target.x, to_target.z)
	var max_turn := deg_to_rad(turn_speed_deg) * delta
	facing_yaw = wrapf(
		facing_yaw + clampf(_angle_diff(facing_yaw, target_yaw), -max_turn, max_turn),
		-PI, PI
	)
	_apply_facing()


func _apply_facing() -> void:
	rotation.y = facing_yaw


func _facing_vector() -> Vector3:
	return Vector3(sin(facing_yaw), 0.0, cos(facing_yaw))


## Shortest signed angle from `from` to `to`, in (-PI, PI].
func _angle_diff(from: float, to: float) -> float:
	return wrapf(to - from, -PI, PI)


func _horizontal_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# ---------------- ANIMATION ----------------

func _update_walk_animation(delta: float) -> void:
	if not anim_player:
		return

	var speed := Vector2(velocity.x, velocity.z).length()
	anim_speed = lerpf(anim_speed, speed, 1.0 - exp(-10.0 * delta))

	var chasing := state == State.CHASE
	var moving_anim: StringName = anim_run_name if chasing else anim_name
	var reference := anim_run_speed_reference if chasing else anim_walk_speed_reference

	if anim_speed > anim_move_threshold:
		if anim_player.current_animation != moving_anim or not anim_player.is_playing():
			anim_player.play(moving_anim, 0.2)
		anim_player.speed_scale = 1.0
	else:
		if anim_idle_name != &"":
			if anim_player.current_animation != anim_idle_name:
				anim_player.play(anim_idle_name, 0.2)
			anim_player.speed_scale = 1.0
		elif anim_player.is_playing():
			anim_player.pause()


# ---------------- TRIGGERS ----------------

func talk_to(source: Node3D) -> void:
	if state == State.CHASE:
		return
	player_ref = source
	suspicion_timer = suspicion_duration
	state = State.SUSPICIOUS


func take_damage(amount: float, attacker: Node3D = null) -> void:
	current_health -= amount

	if is_instance_valid(attacker):
		player_ref = attacker
		nav_agent.target_position = attacker.global_position

	state = State.CHASE
	chase_target_update_timer = 0.0

	if current_health <= 0.0:
		die()


var is_dead: bool = false

func die() -> void:
	if is_dead:
		return
	is_dead = true
	EventBus.enemy_died.emit(self)
	set_physics_process(false)
	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred(&"disabled", true)
	if anim_player and anim_player.has_animation(anim_death_name):
		anim_player.speed_scale = 1.0
		anim_player.play(anim_death_name, 0.1)
		await anim_player.animation_finished
	queue_free()

# ---------------- DEBUG ----------------

func _debug_navmesh_report() -> void:
	var map_rid := get_world_3d().navigation_map
	var regions := NavigationServer3D.map_get_regions(map_rid)

	print("=== %s navmesh report ===" % name)
	print("map valid=%s iteration=%d regions=%d"
			% [map_rid.is_valid(), NavigationServer3D.map_get_iteration_id(map_rid), regions.size()])
	for r in regions:
		print("  region layers=%d enabled=%s bounds=%s" % [
			NavigationServer3D.region_get_navigation_layers(r),
			NavigationServer3D.region_get_enabled(r),
			NavigationServer3D.region_get_bounds(r)
		])
	print("agent.navigation_layers=%d | export mask=%d | resolved sampling mask=%d"
			% [nav_agent.navigation_layers, patrol_navigation_layers, sample_layers])

	var ground := NavigationServer3D.map_get_closest_point(map_rid, global_position)
	print("agent y=%.2f | navmesh y=%.2f" % [global_position.y, ground.y])

	for i in 3:
		print("  raw candidate %d: %s" % [i, NavigationServer3D.map_get_random_point(map_rid, sample_layers, true)])

	var lengths: Array[float] = []
	var unreachable := 0
	for i in 50:
		var p := NavigationServer3D.map_get_random_point(map_rid, sample_layers, true)
		if not p.is_finite() or p.is_zero_approx():
			unreachable += 1
			continue
		var l := _path_length_to(map_rid, p)
		if l < 0.0:
			unreachable += 1
		else:
			lengths.append(l)

	lengths.sort()
	print("unreachable: %d / 50" % unreachable)
	if lengths.is_empty():
		print("no reachable points at all")
	else:
		print("shortest %.1fm | median %.1fm | longest %.1fm" % [
			lengths[0], lengths[lengths.size() / 2], lengths[lengths.size() - 1]
		])
	print("=== end report ===")

# Per-second readout. Once calibration has settled, `horiz` and `3d` should
# track each other closely and both should fall below `pdd` as waypoints are
# reached - that's the agent advancing along the path instead of orbiting.
func _debug_live_readout(delta: float) -> void:
	_debug_timer -= delta
	if _debug_timer > 0.0:
		return
	_debug_timer = 1.0

	var path := nav_agent.get_current_navigation_path()
	var next := nav_agent.get_next_path_position()
	print("%s | st=%d target=%s has=%s | path=%d | horiz=%.2f 3d=%.2f pdd=%.2f hoff=%.2f | fin=%s | spd=%.2f" % [
		name, state,
		nav_agent.target_position, has_patrol_target,
		path.size(),
		_horizontal_distance(global_position, next),
		global_position.distance_to(next),
		nav_agent.path_desired_distance,
		nav_agent.path_height_offset,
		nav_agent.is_navigation_finished(),
		Vector2(velocity.x, velocity.z).length()
	])
	
