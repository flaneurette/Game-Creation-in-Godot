# Godot Snippets Cheat Sheet

Common, reusable GDScript patterns. Most interactables in Godot boil down to the same handful of building blocks

---

#### Declaring variables another script will set

If another script does `body.some_var = true`, that variable `must already exist` on the target script - GDScript won't create it on the fly. This is the #1 cause of `Invalid assignment of property or key` errors.

```gdscript
# On the player script, declare anything other scripts will set:
var is_on_ladder: bool = false
var current_ladder: Area3D = null

var collected_weapon: bool = false
var collected_type: String = ""
var current_collectible: Node3D = null
```

---

#### Show a GUI item

```
@export var collectible_type: String = "gun"
```

---

#### Register something in a group

```gdscript
func _ready():
	add_to_group("player")
```

Put this in your player's `_ready()`. Any script can then check `body.is_in_group("player")` without needing a direct reference to the player node.

---

#### Raycast interaction ("press E to interact")

Instead of walking into a trigger zone, cast a ray from the camera and check what it hits. Common for doors, NPCs, pickup-on-keypress rather than pickup-on-touch.

```gdscript
@onready var camera: Camera3D = $Camera3D

func _physics_process(delta):
	if Input.is_action_just_pressed("interact"):
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(
			camera.global_position,
			camera.global_position - camera.global_transform.basis.z * 3.0
		)
		var result = space_state.intersect_ray(query)
		if result and result.collider.has_method("interact"):
			result.collider.interact()
```

The target object just needs an `interact()` method:
```gdscript
func interact() -> void:
	print("Door opened!")
```

---

#### Custom signals (objects announcing events)

Built-in signals like `body_entered` only fire for physics overlap. Once other systems (HUD, UI, audio, achievements) need to know something happened, define your own.

```gdscript
extends Node3D

signal weapon_collected(type: String)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		weapon_collected.emit(collectible_type)
```

Anywhere else that needs to react:
```gdscript
some_collectible.weapon_collected.connect(_on_weapon_collected)

func _on_weapon_collected(type: String) -> void:
	print("Player picked up: ", type)
```

---

#### Autoload / Singleton (global game state)

For data that needs to persist across scenes - score, inventory, whether a weapon's been collected - rather than living on one specific node.

1. Create a script, e.g. `GameState.gd`:
```gdscript
extends Node

var player_score: int = 0
var has_gun: bool = false
```
2. `Project -> Project Settings -> Autoload` -> add `GameState.gd`, give it a name (`GameState`).
3. Access it from any script, no reference needed:
```gdscript
GameState.player_score += 10
GameState.has_gun = true
```

---

#### Trigger zone (Area3D detecting the player)

The core building block behind ladders, collectibles, checkpoints, damage zones, doors - anything that reacts when the player enters/exits a space.

```gdscript
extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		pass # your logic here

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		pass # your logic here
```

`Requires:` player node added to the `"player"` group (Node tab -> Groups), and an `Area3D` + `CollisionShape3D` sized to the trigger zone.

---

#### Reusable scene with configurable data (@export)

Instead of one script per item type, expose fields in the Inspector so the same scene can be reused with different settings.

```gdscript
extends Node3D

@export var collectible_type: String = "gun"

@onready var area: Area3D = $Area3D

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.collected_weapon = true
		body.collected_type = collectible_type
		body.current_collectible = self
		visible = false
		area.monitoring = false # stop it firing again after collection
```

Drag the same `.tscn` into a level multiple times, change `collectible_type` per instance - no duplicate scripts/scenes needed.

---

#### Moving along a rotated object's own axis

Useful whenever movement needs to follow an object's orientation instead of world axes (ladders, rails, conveyor belts, slides).

```gdscript
var object_up: Vector3 = some_node.global_transform.basis.y.normalized()
velocity = object_up * input_dir * speed
```

`global_transform.basis.y` gives the object's local "up" direction in world space - use `.x` or `.z` for its local right/forward instead, depending on what axis you need to move along.

---

#### Layers & masks quick reference

- `Layer` = what an object *is*.
- `Mask` = what it *reacts to*.
- Two bodies interact if `either one's` Mask includes the other's Layer - doesn't need to be mutual.

| Layer | Name | Used by |
|---|---|---|
| 1 | World | Walls, floors, static geometry |
| 2 | Player | Player's `CharacterBody3D` |
| 3 | Triggers | `Area3D` zones (ladders, doors, pickups) |
| 4 | Solid Props | Objects that collide with World but not Player |
| 5 | Enemies | Enemy bodies |

Set names at: `Project -> Project Settings -> Layer Names -> 3D Physics`
Set per-object at: select `CollisionShape3D`'s parent -> Inspector -> Collision section.

`Recipe - player walks through an object, but it still collides with the world:`
Object: Layer `4`, Mask `1`. Player: Mask does *not* include `4`.

---

#### Tween (smooth animation without an AnimationPlayer)

Good for doors swinging open, items bobbing/rotating, UI fading in - quick one-off animations in code.

```gdscript
var tween = create_tween()
tween.tween_property(self, "position:y", position.y + 2.0, 1.0)
```
`1.0` is the duration in seconds. Chain more steps with `.tween_property()` again, or use `.tween_callback()` to run a function when it finishes.

---

#### Timers (delays without freezing the game)

```gdscript
await get_tree().create_timer(2.0).timeout
queue_free()
```

Common for "respawn item after 5 seconds," "despawn effect after playing," or any delayed action that shouldn't block other logic while waiting.

---

#### Simple state machine (enum-based)

Once you're juggling more than 2-3 booleans (`is_on_ladder`, `is_falling`, `is_attacking`...) an enum + `match` keeps things far more readable and prevents impossible states (e.g. climbing *and* falling at once).

```gdscript
enum State { IDLE, CLIMBING, FALLING, ATTACKING }
var current_state: State = State.IDLE

func _physics_process(delta):
	match current_state:
		State.IDLE:
			pass
		State.CLIMBING:
			pass
		State.FALLING:
			pass
		State.ATTACKING:
			pass
```

---

#### Health / damage pattern

```gdscript
var health: int = 100

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	queue_free() # or trigger a respawn/game-over instead
```

Pairs naturally with the trigger-zone pattern (#1) - a damage zone's `_on_body_entered` just calls `body.take_damage(10)` if the body has that method:
```gdscript
func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(10)
```

---

#### Debugging checklist

- `Invalid assignment of property or key` -> the variable isn't declared on the target script. See #3.
- Signal never fires (`body_entered` silent) -> check Layer/Mask overlap between the two objects; this is the most common silent failure in 3D.
- Player bumps into something that should be walk-through -> it still has solid collision (`StaticBody3D`) on top of/instead of the `Area3D` trigger. See #6.
- Object drifts / stutters while moving along an angled surface -> you're using world-axis (`velocity.y`) instead of the object's own local axis. See #5.
- `Debug -> Visible Collision Shapes` (top menu while running) draws all collision shapes as green outlines - the fastest way to see what's actually overlapping what.
