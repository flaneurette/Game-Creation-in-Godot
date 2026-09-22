# Godot Math Functions Cheat Sheet

A condensed reference for common math functions used in Godot (GDScript syntax, Godot 4.x).

---

## Understanding x, y, z

Before the functions below make sense, it helps to know what `x`, `y`, and `z` actually represent. They're just the individual **components** (axes) of a position or direction in space, bundled together into a `Vector2` or `Vector3` object. In 2D, `x` is horizontal (positive = right) and `y` is vertical (positive = **down** on screen in Godot, which trips up a lot of newcomers coming from math class where up is positive). In 3D, `z` is added as depth (positive = toward the camera by default, i.e. "out of the screen"), following Godot's right-handed coordinate system. You can read or write each axis individually (`velocity.x`, `position.z`), or manipulate the whole vector at once - both are used constantly depending on whether you're changing one axis (like jump height on `y`) or moving the object as a whole.

```gdscript
var pos = Vector3(5, 2, -3)
print(pos.x)   # 5  -> right/left position
print(pos.y)   # 2  -> up/down position (height)
print(pos.z)   # -3 -> forward/back position (depth)

# common pattern: only touch one axis, leave the rest alone
velocity.y = -9.8  # apply gravity without changing horizontal movement
```

---

## sin()

`sin(angle_rad)` returns the sine of an angle given in **radians**, producing a smooth wave value between -1 and 1. It's most often used to create oscillating motion, like bobbing, pulsing, or wave patterns, because as the input increases steadily the output cycles smoothly up and down.

```gdscript
extends Node2D

var time := 0.0
var base_y := 0.0

func _ready():
    base_y = position.y

func _process(delta):
    time += delta
    # oscillates between base_y - 10 and base_y + 10, twice per second
    position.y = base_y + sin(time * TAU) * 10.0
```

---

## cos()

`cos(angle_rad)` returns the cosine of an angle in radians, also oscillating between -1 and 1, but offset a quarter cycle from `sin()`. Because of this offset, `sin()` and `cos()` together are the standard way to convert an angle into a 2D direction (x, y), which is why they're the backbone of circular motion.

```gdscript
extends Node2D

@export var radius := 100.0
@export var speed := 1.0  # radians per second
var angle := 0.0
var center: Vector2

func _ready():
    center = position

func _process(delta):
    angle += speed * delta
    # cos drives x, sin drives y -> traces a circle around "center"
    var offset = Vector2(cos(angle), sin(angle)) * radius
    position = center + offset
```

---

## tan()

`tan(angle_rad)` returns the tangent of an angle (sine divided by cosine), which grows very steeply and shoots to infinity near 90°/270°. It's less common in gameplay code but useful for projecting angles onto a flat plane, such as computing the height difference needed for a given slope angle or field-of-view calculations.

```gdscript
# Given a camera's horizontal field of view, find how wide the
# visible area is at a certain distance in front of the camera.
@export var fov_degrees := 60.0
@export var distance := 10.0

func get_visible_width() -> float:
    var fov_rad = deg_to_rad(fov_degrees)
    var half_width = tan(fov_rad / 2.0) * distance
    return half_width * 2.0
```

---

## atan2()

`atan2(y, x)` takes a direction as separate y and x components and returns the angle (in radians) of that direction, correctly handling all four quadrants (unlike plain `atan()`, which can't tell if the target is behind you). It's the standard way to find "what angle do I need to face to point from A to B," used constantly for aiming, rotation, and AI facing logic.

```gdscript
extends CharacterBody2D

@export var target: Node2D

func _process(delta):
    var direction = target.global_position - global_position
    # note the argument order: y first, then x
    var angle_to_target = atan2(direction.y, direction.x)
    rotation = angle_to_target  # turret/character instantly faces the target
```

---

## atan()

`atan(x)` returns the angle whose tangent is `x`, but only ever within a half-circle range (-90° to 90°), meaning it can't distinguish "up-left" from "down-right" the way `atan2()` can. It's mainly useful when you already have a single ratio (not separate x/y components) and know the result should stay within that limited range, such as computing a slope angle from a single rise/run value.

```gdscript
# Estimate the incline angle of a ramp from its height and length.
@export var ramp_height := 3.0
@export var ramp_length := 10.0

func get_ramp_angle_degrees() -> float:
    var slope_ratio = ramp_height / ramp_length
    var slope_angle_rad = atan(slope_ratio)
    return rad_to_deg(slope_angle_rad)
```

---

## Vector2()

`Vector2(x, y)` is Godot's built-in type for a 2D point or direction, bundling two floats together so you can add, subtract, scale, and measure them as a single unit instead of juggling loose x/y variables. Almost everything in 2D Godot (position, velocity, direction, mouse coordinates) is a `Vector2`, and the type comes with useful built-in methods like `.length()`, `.normalized()`, and `.distance_to()`.

```gdscript
extends CharacterBody2D

@export var speed := 200.0

func _physics_process(delta):
    var input_dir = Vector2(
        Input.get_axis("move_left", "move_right"),
        Input.get_axis("move_up", "move_down")
    )
    velocity = input_dir.normalized() * speed
    move_and_slide()

    # distance-based logic is easy with vector math
    var mouse_pos = get_global_mouse_position()
    if global_position.distance_to(mouse_pos) < 50.0:
        print("mouse is close to the player")
```

---

## Vector3() / "vector"

`Vector3(x, y, z)` is the 3D equivalent of `Vector2`, used for positions, directions, velocities, and normals in 3D space, and it supports the same arithmetic (`+`, `-`, `*`, dot/cross products, length, normalization) plus a `z` component for depth. Generically, a "vector" in Godot just means one of these fixed-size numeric tuples used to represent a point or direction in space - the same underlying idea, just with 2 or 3 numbers depending on whether you're in 2D or 3D.

```gdscript
extends CharacterBody3D

const GRAVITY := Vector3(0, -9.8, 0)
@export var jump_force := 6.0
@export var speed := 5.0

func _physics_process(delta):
    if not is_on_floor():
        velocity += GRAVITY * delta

    if is_on_floor() and Input.is_action_just_pressed("jump"):
        velocity.y = jump_force  # only touch the vertical axis

    var input_dir = Input.get_vector("left", "right", "forward", "back")
    var move_dir = Vector3(input_dir.x, 0, input_dir.y).normalized()
    velocity.x = move_dir.x * speed
    velocity.z = move_dir.z * speed

    move_and_slide()
```

---

## lerp()

`lerp(from, to, weight)` (linear interpolation) returns a value that is `weight` fraction of the way between `from` and `to` - `0.0` gives `from`, `1.0` gives `to`, and `0.5` gives the exact midpoint. It works on floats, `Vector2`, `Vector3`, and colors, and is the go-to tool for smooth transitions like camera easing, fading, or gradually moving a value toward a target - note that calling it every frame with a small weight (like `0.1`) creates a natural "ease out" effect, since the remaining distance shrinks each step.

```gdscript
extends Camera2D

@export var target: Node2D
@export var follow_speed := 0.08  # 0 = never catches up, 1 = instant snap

func _process(delta):
    # each frame, move 8% of the remaining distance toward the target
    global_position = global_position.lerp(target.global_position, follow_speed)

func fade_out(sprite: Sprite2D, delta: float):
    sprite.modulate.a = lerp(sprite.modulate.a, 0.0, 2.0 * delta)
```

---

## slerp()

`slerp(from, to, weight)` (spherical linear interpolation) works like `lerp()` but interpolates along the *shortest arc* between two directions/rotations at a constant angular speed, rather than blending straight-line coordinates. This matters for rotations and quaternions, since a plain `lerp()` on angles or facing directions can produce unnatural speed changes, jump the "long way around," or even shrink a vector's length mid-blend, while `slerp()` keeps the turn smooth, consistent, and correctly normalized throughout.

```gdscript
extends CharacterBody3D

@export var target: Node3D
@export var turn_speed := 0.05

func _physics_process(delta):
    var to_target = (target.global_position - global_position).normalized()
    var current_quat = global_transform.basis.get_rotation_quaternion()

    # build the rotation that faces the target, then slerp toward it
    var target_basis = Basis.looking_at(to_target, Vector3.UP)
    var target_quat = target_basis.get_rotation_quaternion()

    var new_quat = current_quat.slerp(target_quat, turn_speed)
    global_transform.basis = Basis(new_quat)
```

---

## Bonus: clamp()

`clamp(value, min, max)` restricts a number to stay within a given range, returning `min` if the value is too low, `max` if it's too high, and the value itself otherwise. It's essential for keeping things like health, zoom levels, or input values from going out of valid bounds, and it also works component-wise on vectors in Godot 4.

```gdscript
var health := 100.0
var max_health := 100.0

func take_damage(amount: float):
    health = clamp(health - amount, 0.0, max_health)
    if health <= 0.0:
        die()

func zoom_camera(delta_zoom: float):
    camera.zoom = clamp(camera.zoom + delta_zoom, 0.5, 3.0)
```

---

## Bonus: move_toward()

`move_toward(from, to, delta_amount)` moves a value a fixed step toward a target without overshooting it, which is different from `lerp()` because the speed here is constant (linear) rather than slowing down as it approaches the target - it just stops exactly at `to` once it gets there. It's ideal for things like gradual acceleration/deceleration, health regeneration ticking up at a fixed rate, or rotating at a fixed max turn speed.

```gdscript
extends CharacterBody2D

@export var max_speed := 300.0
@export var acceleration := 800.0
@export var friction := 600.0

func _physics_process(delta):
    var input_dir = Input.get_axis("left", "right")
    var target_speed = input_dir * max_speed

    if input_dir != 0:
        velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, friction * delta)

    move_and_slide()
```

---

## Bonus: normalized() / dot()

`vector.normalized()` returns the same direction scaled down to a length of exactly 1, which is essential before using a vector purely as a direction (e.g. for movement input) so that diagonal movement isn't faster than straight movement (an un-normalized diagonal input like `(1, 1)` has a length of ~1.41, not 1). `vector_a.dot(vector_b)` returns a single number describing how aligned two normalized vectors are: `1.0` means pointing the exact same way, `-1.0` means exactly opposite, and `0.0` means perpendicular - commonly used to check if something is roughly in front of or behind another object, like a field-of-view or backstab check.

```gdscript
extends CharacterBody2D

@export var speed := 200.0

func _physics_process(delta):
    var input_dir = Vector2(
        Input.get_axis("left", "right"),
        Input.get_axis("up", "down")
    )
    # without normalized(), diagonal movement would be ~41% faster
    velocity = input_dir.normalized() * speed
    move_and_slide()

func is_enemy_in_front(facing_dir: Vector2, to_enemy: Vector2) -> bool:
    var alignment = facing_dir.normalized().dot(to_enemy.normalized())
    return alignment > 0.7  # roughly within a ~45 degree cone ahead
```
