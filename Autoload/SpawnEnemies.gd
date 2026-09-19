extends Node
## SpawnEnemies.gd  (AutoLoad, Godot 4.2+)
##
## Spawns a number of Enemy scenes at random positions on the floor of the
## current level (NavigationRegion3D -> Ground).
##
## Setup:
##   Project > Project Settings > Globals > Autoload > add this script as "SpawnEnemies".
##
## Usage:
##   - Automatic: with auto_spawn = true it spawns once, right after the main scene has loaded.
##   - Manual:    SpawnEnemies.spawn_enemies()   (e.g. from your level's _ready(), or on a wave)
##                SpawnEnemies.clear_enemies()
##   - Override settings from code before spawning:
##                SpawnEnemies.enemy_count = 50
##                SpawnEnemies.spawn_enemies()

## Emitted after spawning, with all the enemies that were created.
signal enemies_spawned(enemies: Array[Node3D])

@export_group("Enemies")
## The enemy scene to instance.
@export_file("*.tscn") var enemy_scene_path: String = "res://Enemy.tscn"
## How many enemies to spawn.
@export var enemy_count: int = 300
## Minimum distance (in meters, on the XZ plane) between two enemies.
@export var min_spacing: float = 2.0
## Give every enemy a random rotation around the Y axis.
@export var random_y_rotation: bool = true
## Lift the enemy slightly above the floor so it doesn't clip into it.
@export var spawn_height_offset: float = 0.05

@export_group("Level")
## Path to the ground node, relative to the current scene's root node.
@export var ground_path: NodePath = ^"NavigationRegion3D"
## Keep enemies this far away from the edges of the ground.
@export var edge_margin: float = 1.0
## Only spawn where the baked navigation mesh is (and snap to it).
@export var snap_to_navmesh: bool = true
## How far (in meters) a random point may be from the navmesh before it is rejected.
@export var navmesh_tolerance: float = 1.0

@export_group("Behaviour")
## Spawn automatically once the main scene is loaded.
@export var auto_spawn: bool = true
## 0 = different every run. Any other number gives the same layout every run.
@export var random_seed: int = 0
## How many random positions to try per enemy before giving up on it.
@export var max_attempts_per_enemy: int = 30

var _rng := RandomNumberGenerator.new()
var _container: Node3D


func _ready() -> void:
	if not auto_spawn:
		return
	# Wait until the main scene exists and the physics/navigation servers know about it.
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	spawn_enemies()


## Spawns enemies on the ground of the current scene. Removes previously spawned enemies first.
func spawn_enemies() -> Array[Node3D]:
	var spawned: Array[Node3D] = []

	var level := get_tree().current_scene
	if level == null:
		push_error("SpawnEnemies: there is no current scene.")
		return spawned

	var enemy_scene := load(enemy_scene_path) as PackedScene
	if enemy_scene == null:
		push_error("SpawnEnemies: could not load enemy scene '%s'." % enemy_scene_path)
		return spawned

	var ground := _find_ground(level)
	if ground == null:
		push_error("SpawnEnemies: could not find the ground at '%s' (or any node named 'Ground')." % ground_path)
		return spawned

	var bounds := _get_ground_bounds(ground)
	if bounds.size == Vector3.ZERO:
		push_error("SpawnEnemies: '%s' has no mesh/CSG shape to take the size from." % ground.name)
		return spawned

	var nav_region := _find_nav_region(ground)
	var space := ground.get_world_3d().direct_space_state

	if random_seed != 0:
		_rng.seed = random_seed
	else:
		_rng.randomize()

	clear_enemies()
	_container = Node3D.new()
	_container.name = "Enemies"
	level.add_child(_container)

	var used_positions: Array[Vector3] = []
	for i in enemy_count:
		var point: Variant = _find_spawn_point(bounds, ground, nav_region, space, used_positions)
		if point == null:
			continue # no free spot found for this one

		var pos: Vector3 = point
		var enemy := enemy_scene.instantiate() as Node3D
		if enemy == null:
			push_error("SpawnEnemies: the root node of the enemy scene must be a Node3D (or derived).")
			return spawned

		_container.add_child(enemy)
		enemy.global_position = pos + Vector3.UP * spawn_height_offset
		if random_y_rotation:
			enemy.rotation.y = _rng.randf_range(0.0, TAU)

		used_positions.append(pos)
		spawned.append(enemy)

	if spawned.size() < enemy_count:
		push_warning(("SpawnEnemies: only %d of %d enemies could be placed. Lower min_spacing / edge_margin, "
				+ "or check that Ground has a collision shape (and a baked navmesh if snap_to_navmesh is on).")
				% [spawned.size(), enemy_count])

	enemies_spawned.emit(spawned)
	return spawned


## Removes all enemies that were created by this script.
func clear_enemies() -> void:
	if is_instance_valid(_container):
		if _container.get_parent():
			_container.get_parent().remove_child(_container)
		_container.queue_free()
	_container = null


# ------------------------------------------------------------------------------------------------

func _find_spawn_point(bounds: AABB, ground: Node, nav_region: NavigationRegion3D,
		space: PhysicsDirectSpaceState3D, used_positions: Array[Vector3]) -> Variant:
	var min_x := bounds.position.x + edge_margin
	var max_x := bounds.end.x - edge_margin
	var min_z := bounds.position.z + edge_margin
	var max_z := bounds.end.z - edge_margin
	if min_x >= max_x or min_z >= max_z:
		return null # edge_margin is bigger than the ground

	var min_spacing_sq := min_spacing * min_spacing
	var use_navmesh := false
	var nav_map := RID()
	if snap_to_navmesh and nav_region != null:
		nav_map = nav_region.get_navigation_map()
		# iteration id 0 = the map has not been synchronized yet, so it can't be queried.
		use_navmesh = nav_map.is_valid() and NavigationServer3D.map_get_iteration_id(nav_map) > 0

	for attempt in max_attempts_per_enemy:
		var x := _rng.randf_range(min_x, max_x)
		var z := _rng.randf_range(min_z, max_z)

		# 1. Spread out: stay away from enemies that are already placed.
		var flat := Vector2(x, z)
		var too_close := false
		for other in used_positions:
			if Vector2(other.x, other.z).distance_squared_to(flat) < min_spacing_sq:
				too_close = true
				break
		if too_close:
			continue

		# 2. Find the real floor height with a ray from above.
		var query := PhysicsRayQueryParameters3D.create(
				Vector3(x, bounds.end.y + 50.0, z),
				Vector3(x, bounds.position.y - 50.0, z))
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			continue # outside the ground, or the ground has no collision shape

		# 3. Make sure we hit the ground and not a rock, wall, tree, ...
		var collider := hit["collider"] as Node
		if collider == null:
			continue
		if collider != ground and not ground.is_ancestor_of(collider) and not collider.is_ancestor_of(ground):
			continue

		var pos: Vector3 = hit["position"]

		# 4. Optionally only accept points that are on the navigation mesh.
		if use_navmesh:
			var nav_point := NavigationServer3D.map_get_closest_point(nav_map, pos)
			if nav_point.distance_to(pos) > navmesh_tolerance:
				continue
			pos = nav_point

		return pos

	return null


func _find_ground(level: Node) -> Node3D:
	var node := level.get_node_or_null(ground_path) as Node3D
	if node == null:
		node = level.find_child("Ground", true, false) as Node3D
	return node


func _find_nav_region(ground: Node) -> NavigationRegion3D:
	var node := ground.get_parent()
	while node != null:
		if node is NavigationRegion3D:
			return node
		node = node.get_parent()
	return null


## World-space bounding box of everything visible in the Ground node (MeshInstance3D, CSG, ...).
func _get_ground_bounds(ground: Node) -> AABB:
	var nodes: Array[Node] = [ground]
	nodes.append_array(ground.find_children("*", "VisualInstance3D", true, false))

	var result := AABB()
	var found := false
	for node in nodes:
		if node is VisualInstance3D:
			var box: AABB = node.global_transform * node.get_aabb()
			result = box if not found else result.merge(box)
			found = true
	return result
