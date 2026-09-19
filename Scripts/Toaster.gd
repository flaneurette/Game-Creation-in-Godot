extends CanvasLayer

@export var gun_icon: Texture2D
@export var explosives_icon: Texture2D
@export var knife_icon: Texture2D

@export var icon_size: Vector2 = Vector2(32, 32)
@export var icon_color: Color = Color.WHITE
@export_range(0.0, 1.0) var icon_opacity: float = 1.0

@onready var texture_rect: TextureRect = $MarginContainer/TextureRect

var icons: Dictionary
var active_tween: Tween

func _ready() -> void:
	icons = {
		"gun": gun_icon,
		"explosives": explosives_icon,
		"knife": knife_icon,
	}
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	texture_rect.custom_minimum_size = icon_size
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Stop the MarginContainer from stretching this to fill available space —
	# without this, custom_minimum_size is only a floor, not a fixed size.
	texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	texture_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	texture_rect.modulate = Color(icon_color.r, icon_color.g, icon_color.b, 0.0)

	EventBus.weapon_switched.connect(_on_weapon_switched)

func _on_weapon_switched(type: String) -> void:
	if not icons.has(type) or icons[type] == null:
		push_warning("No icon assigned for weapon type: " + type)
		return

	texture_rect.texture = icons[type]

	if active_tween and active_tween.is_valid():
		active_tween.kill()

	texture_rect.modulate = Color(icon_color.r, icon_color.g, icon_color.b, icon_opacity)
	active_tween = create_tween()
	active_tween.tween_interval(0.3)
	active_tween.tween_property(texture_rect, "modulate:a", 0.0, 2.0)
