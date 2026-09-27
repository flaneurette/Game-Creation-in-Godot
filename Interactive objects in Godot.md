# Add interactive objects in Godot

In this text we are going to create a climbable object, like a ladder. We assume you already ran the `ladder.md` tutorial to create a 3D ladder.

> Note: It is important to realize that we cannot have a collision placed on the ladder itself. If there is one, remove it by re-importing the `.glb` model and tick `off` the physics checkbox. We add a collision on it ourselves manually.

> TIP: It is best if you create a `new scene` for each objects with special properties, such as a climbable ladder. Such as: Ladder.tscn

#### Create our own solid ladder.

- Add `StaticBody3D` to the ladder object.
- Add a child to the statisbody: `CollisionShape3D`
- Set these dimensions in `transform` -> `scale`: `X: 1.0, Y: 24.0, Z: 0.2`

The ladder now has a fixed Collision shape, so the player cannot walk through it. 
- Set Y to the height of your ladder. (24 meters in our case).

> Note: Be sure to make the `Z` smaller than the next trigger zone, otherwise, the player cannot climb.

#### Setup the ladder 3D area

Add the climbable trigger zone.

- Right-click the ladder node in the Scene panel -> Add Child Node  -> search for `Area3D` -> Add.
- Right-click that new `Area3D` -> Add Child Node -> search for `CollisionShape3D` -> Add.
- Select the CollisionShape3D. In the Inspector, click the Shape property -> `New BoxShape3D`
- A wireframe box gizmo appears in the 3D viewport. Use the orange handles to resize/position it so it covers the ladder's climbable area - roughly matching the ladder's width/depth, and tall enough to cover its full height. It's fine (even good) to make it slightly wider than the visual mesh so the player doesn't need pixel-perfect alignment.

**Optional:**

Set collision layers/masks

Select the Area3D. In the Inspector, find Collision -> Layer and Collision -> Mask.
Set its Layer to whatever you're using for triggers/interactables (e.g. layer 3, if layer 1 = world, layer 2 = player).

#### Movement.gd

Add this code to your `Player` scripts.

The code follows the ladder, even if it is placed at an angle.

```
var current_ladder: Area3D = null
var is_on_ladder: bool = false
var climb_speed: float = 1.0

func _ready():
	# This is important!
	add_to_group("player")

func _physics_process(delta):
	
	if is_on_ladder:
		var input_dir := Input.get_axis("climbdown", "climbup")
		var ladder_up: Vector3 = current_ladder.global_transform.basis.y.normalized()
		velocity = ladder_up * input_dir * climb_speed
		move_and_slide()
	else:
	 # other scripts or pass:
	 pass
```

#### Climbing.gd

Add this script to the `Area3D` of the ladder node:

```
extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.is_on_ladder = true
		body.current_ladder = self

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.is_on_ladder = false
		body.current_ladder = null

```

> Note: If you get a stuttering climb effect, it probably means the player climbs at an angle. Adjust `w/s` keys to get on the ladder again. This is exactly as it behaves in real life.

#### Set up input actions

In Project -> Project Settings -> Input Map, add two actions:

- `climbup` - bind to e.g. W / Up Arrow
- `climbdown` - bind to e.g. S / Down Arrow

#### Test it!

Now run the game and test it. It should work.

#### Layers (extra)

The core rule

- Layer: what an object is in relation to it.
- Mask: what it reacts to when interacted with.

Two bodies interact if either one's Mask includes the other's Layer. It doesn't need to be mutual.

Example:

- Ladder (Layer 4) with Mask 1 will collide with a Wall (Layer 1), even if the Wall's Mask doesn't include layer 4.

Where to set it

- Select a CollisionShape3D's parent body (StaticBody3D, RigidBody3D, CharacterBody3D, Area3D) -> Inspector -> Collision section -> Layer and Mask checkboxes.
- Name your layers so the checkboxes show labels instead of numbers: Project -> Project Settings -> Layer Names -> 3D Physics
