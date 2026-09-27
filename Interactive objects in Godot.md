# Add interactive objects in Godot

In this text we are going to create a climable object, like a ladder. We assume you already ran the `ladder.md` tutorial to create a 3D ladder.

Also, make sure the ladder itself already has a collision shape to it, so that you cannot walk through it. This can be done most easily upon import of the `.glb`


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
