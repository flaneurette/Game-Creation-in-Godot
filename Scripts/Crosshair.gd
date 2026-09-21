extends Control
## Attach to the Crosshair Control node. In the Inspector's Layout menu,
## set Anchor Preset to "Full Rect" so this node covers the whole screen —
## that guarantees the crosshair is drawn at the true screen center
## regardless of what container it's nested inside.

@export var base_gap: float = 6.0
@export var line_length: float = 8.0
@export var line_thickness: float = 2.0
@export var color: Color = Color.WHITE

var current_spread: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Hidden while unarmed; shown once the player tabs into a weapon.
	visible = false
	EventBus.weapon_switched.connect(_on_weapon_switched)

func _on_weapon_switched(_type: String) -> void:
	visible = true

func _draw() -> void:
	# Use the viewport center rather than this node's own size, so it stays
	# correct even if a parent container resizes or repositions this node.
	var center := get_viewport_rect().size / 2
	var gap := base_gap + current_spread

	draw_line(center + Vector2(-gap - line_length, 0), center + Vector2(-gap, 0), color, line_thickness)
	draw_line(center + Vector2(gap, 0), center + Vector2(gap + line_length, 0), color, line_thickness)
	draw_line(center + Vector2(0, -gap - line_length), center + Vector2(0, -gap), color, line_thickness)
	draw_line(center + Vector2(0, gap), center + Vector2(0, gap + line_length), color, line_thickness)

## Call this from your weapon script whenever spread changes (e.g. while firing).
func set_spread(value: float) -> void:
	current_spread = value
	queue_redraw()
