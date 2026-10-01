# Animated collectible

Creating a animated collectible is simple.

<img src="Examples/HealthCoin.png" />

It is possible to code an animation in Godot:

```
@export var spin_speed := 2.0  # radians per second
@onready var area: Area3D = $Area3D

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	rotate_y(spin_speed * delta)  # Y is "up" in Godot
```

But we want to show how to do it in Blender as well.

So the following tutorial is about creating a Health Coin, and animating it in blender.
	
#### Create health coin

- Create new blender document
- Add a cylinder, and shape it to a coin.
- Add two 3D cubes and make them elongated into a cross.
- `Ctrl+J` to join the cross.
- Add bevel to it: `modifiers` in `right panel`, add `bevel`.

Add some color to both objects.

Save document.

#### Animation.

Open animation tab.

- Set the view to `front orthographic`
- Rewind the animation needle to zero/one
- Hover over the object, press `I`, then: Rotation.

> Keyframes will appear in the amination editor. Leave them as is.

Then:

- Move the blue needle to position 50.
- Press `N`
- Add: `90` in the `Z` `rotation` box.
- Hover over the object, press `I`, then: `Rotation`.

Repeat:

- Move the blue needle to position 100.
- Press `N`
- Add: `180` in the `Z` `rotation` box.
- Hover over the object, press `I`, then: `Rotation`.

Repeat:

- Move the blue needle to position 150.
- Press `N`
- Add: `270` in the `Z` `rotation` box.
- Hover over the object, press `I`, then: `Rotation`.

Repeat:

- Move the blue needle to position 200.
- Press `N`
- Add: `360` in the `Z` `rotation` box.
- Hover over the object, press `I`, then: `Rotation`.
  
Then:

Select all keyframes, `A`, then `T` and select `linear` for smooth keyframes.

#### Finish

Next, limit the animation duration to 200. In the bottom right of the animation editor, there is a small menu: `Start - End`

Set `End` to: `200`

Export it as: `HealthCoin.glb`

Press Spacebar to see animation.

That is it.

# In Godot

Do the following:

- Double click the GLB file.
- Under AnimationPlayer there should be an action, perhaps it is called: `Cube_001Action`. Click it. Then in the right menu set `Loop Mode` to `Linear`
- Click ReImport

Now it is ready to use.

In Godot, you might have to start the animation:

```
func _ready() -> void:
	var player: AnimationPlayer = $AnimationPlayer
	var anim: Animation = player.get_animation("Cube_001Action")
	anim.loop_mode = Animation.LOOP_LINEAR
	player.play("Cube_001Action")
```

For further scripting the `collectible`, open the readme for: `Collectibles in Godot.md` to understand how to collect the actual object and add it to the player's HUD.

This was it.
