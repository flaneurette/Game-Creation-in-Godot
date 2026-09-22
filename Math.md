# Godot Math Functions Cheat Sheet

A condensed reference for common math functions used in Godot (GDScript syntax, Godot 4.x).

---

## sin()

`sin(angle_rad)` returns the sine of an angle given in **radians**, producing a smooth wave value between -1 and 1. It's most often used to create oscillating motion, like bobbing, pulsing, or wave patterns, because as the input increases steadily the output cycles smoothly up and down.

```gdscript
func _process(delta):
    time += delta
    position.y = base_y + sin(time * 2.0) * 10.0  # bobs up and down
```

---

## cos()

`cos(angle_rad)` returns the cosine of an angle in radians, also oscillating between -1 and 1, but offset a quarter cycle from `sin()`. Because of this offset, `sin()` and `cos()` together are the standard way to convert an angle into a 2D direction (x, y), which is why they're the backbone of circular motion.

```gdscript
func _process(delta):
    angle += delta
    var offset = Vector2(cos(angle), sin(angle)) * radius
    position = center + offset  # moves in a circle
```

---

## tan()

`tan(angle_rad)` returns the tangent of an angle (sine divided by cosine), which grows very steeply and shoots to infinity near 90°/270°. It's less common in gameplay code but useful for projecting angles onto a flat plane, such as computing the height difference needed for a given slope angle or field-of-view calculations.

```gdscript
var fov_rad = deg_to_rad(60.0)
var half_width_at_distance = tan(fov_rad / 2.0) * distance
```

---

## atan2()

`atan2(y, x)` takes a direction as separate y and x components and returns the angle (in radians) of that direction, correctly handling all four quadrants (unlike plain `atan()`). It's the standard way to find "what angle do I need to face to point from A to B," used constantly for aiming, rotation, and AI facing logic.

```gdscript
var direction = target_position - position
var angle = atan2(direction.y, direction.x)
rotation = angle  # rotate node to face the target
```

---

## atan()

`atan(x)` returns the angle whose tangent is `x`, but only ever within a half-circle range (-90° to 90°), meaning it can't tell "up-left" from "down-right" the way `atan2()` can. It's mainly useful when you already have a single ratio (not separate x/y components) and know the result should stay within that limited range, such as slope-angle calculations from a single rise/run value.

```gdscript
var slope_ratio = height_diff / horizontal_distance
var slope_angle = atan(slope_ratio)
```

---

## Vector2()

`Vector2(x, y)` is Godot's built-in type for a 2D point or direction, bundling two floats together so you can add, subtract, scale, and measure them as a single unit instead of juggling loose x/y variables. Almost everything in 2D Godot (position, velocity, direction, mouse coordinates) is a `Vector2`.

```gdscript
var velocity = Vector2(200, 0)
position += velocity * delta  # move right at 200 px/sec
```

---

## Vector3() / "vector"

`Vector3(x, y, z)` is the 3D equivalent of `Vector2`, used for positions, directions, velocities, and normals in 3D space, and it supports the same arithmetic (`+`, `-`, `*`, dot/cross products, length, normalization). Generically, a "vector" in Godot just means one of these fixed-size numeric tuples used to represent a point or direction in space.

```gdscript
var gravity = Vector3(0, -9.8, 0)
velocity += gravity * delta
global_translate(velocity * delta)
```

---

## lerp()

`lerp(from, to, weight)` (linear interpolation) returns a value that is `weight` fraction of the way between `from` and `to` - `0.0` gives `from`, `1.0` gives `to`, and `0.5` gives the exact midpoint. It works on floats, `Vector2`, `Vector3`, and colors, and is the go-to tool for smooth transitions like camera easing, fading, or gradually moving toward a target value.

```gdscript
# smoothly move camera toward target position each frame
camera.position = camera.position.lerp(target.position, 0.1)
```

---

## slerp()

`slerp(from, to, weight)` (spherical linear interpolation) works like `lerp()` but interpolates along the *shortest arc* between two directions/rotations at a constant angular speed, rather than blending straight-line coordinates. This matters for rotations and quaternions, since a plain `lerp()` on angles or facing directions can produce unnatural speed changes or take the "long way around," while `slerp()` keeps the turn smooth and consistent.

```gdscript
# smoothly rotate a Quaternion toward a target orientation
transform.basis = Basis(current_quat.slerp(target_quat, 0.05))
```

---

## Bonus: clamp()

`clamp(value, min, max)` restricts a number to stay within a given range, returning `min` if the value is too low, `max` if it's too high, and the value itself otherwise. It's essential for keeping things like health, zoom levels, or input values from going out of valid bounds.

```gdscript
health = clamp(health - damage, 0, max_health)
```

---

## Bonus: move_toward()

`move_toward(from, to, delta_amount)` moves a value a fixed step toward a target without overshooting it, which is different from `lerp()` because the speed is constant (linear) rather than slowing down as it approaches the target. It's ideal for things like gradual acceleration/deceleration or rotating at a fixed max turn speed.

```gdscript
current_speed = move_toward(current_speed, target_speed, acceleration * delta)
```

---

## Bonus: normalized() / dot()

`vector.normalized()` returns the same direction scaled down to a length of exactly 1, which is essential before using a vector purely as a direction (e.g. for movement input) so that diagonal movement isn't faster than straight movement. `vector_a.dot(vector_b)` returns a single number describing how aligned two vectors are (positive if pointing the same general way, negative if opposite, zero if perpendicular), commonly used for things like checking if an enemy is in front of or behind the player.

```gdscript
var input_dir = Vector2(Input.get_axis("left","right"), Input.get_axis("up","down")).normalized()
velocity = input_dir * speed

if facing_direction.dot(to_enemy_direction) > 0:
    print("enemy is roughly in front of me")
```
