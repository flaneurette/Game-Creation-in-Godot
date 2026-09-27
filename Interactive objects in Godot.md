# Add interactive objects in Godot

In this text we are going to create a climable object, like a ladder. We assume you already ran the `ladder.md` tutorial to create a 3D ladder. Also, make sure the ladder itself already has a collision shape to it, so that you cannot walk through it. This can be done most easily upon import of the `.glb`

#### Setup the 3D model.

- In the filelist, select your 3D model.
- Double click it
- Tick `on` Physics.
- Make sure Body Type set to StaticBody3D
- Click `Reimport`

This makes sure the model now has a collider.

#### Setup the ladder 3D area

Add the climbable trigger zone

The .glb mesh itself has no collision/trigger logic.

- Right-click the ladder node in the Scene panel -> Add Child Node  -> search for `Area3D` -> Add.
- Right-click that new `Area3D` -> Add Child Node -> search for `CollisionShape3D` -> Add.
- Select the CollisionShape3D. In the Inspector, click the Shape property -> `New BoxShape3D`
- A wireframe box gizmo appears in the 3D viewport. Use the orange handles to resize/position it so it covers the ladder's climbable area - roughly matching the ladder's width/depth, and tall enough to cover its full height. It's fine (even good) to make it slightly wider than the visual mesh so the player doesn't need pixel-perfect alignment.

**Optional:**

Set collision layers/masks

Select the Area3D. In the Inspector, find Collision -> Layer and Collision -> Mask.
Set its Layer to whatever you're using for triggers/interactables (e.g. layer 3, if layer 1 = world, layer 2 = player).

#### Movement.gd

Add this script to your `Player` scripts

```
var current_ladder: Area3D = null
var is_on_ladder: bool = false
var climb_speed: float = 1.0

func _physics_process(delta):
	
	if is_on_ladder:
		var input_dir := Input.get_axis("climbdown", "climbup")
		velocity.y = input_dir * climb_speed
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
	else:
	 # other scripts or pass:
	 pass
```

#### Climbing.gd

Add:

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
