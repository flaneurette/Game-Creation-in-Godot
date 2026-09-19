extends CanvasLayer
## Attach this script to the CanvasLayer node.
## Update the NodePaths below to match your actual scene tree.

@onready var health_bar: ProgressBar = $HUD/HealthPanel/HealthBar
@onready var health_label: RichTextLabel = $HUD/HealthPanel/HealthLabel
@onready var ammo_bar: ProgressBar = $HUD/AmmoPanel/AmmoBar
@onready var ammo_label: RichTextLabel = $HUD/AmmoPanel/AmmoLabel

func _ready() -> void:
	ammo_label.bbcode_enabled = true
	health_label.bbcode_enabled = true
	health_bar.value = GameManager.health
	ammo_bar.max_value = GameManager.getMaxAmmo('gun')
	ammo_bar.value = GameManager.bullets

	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_ammo_changed.connect(_on_ammo_changed)

func _on_health_changed(current: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
	health_label.text = "%d / %d" % [current, max_health]

func _on_ammo_changed(current: int, max_ammo: int) -> void:
	ammo_bar.max_value = max_ammo
	ammo_bar.value = current
	var color := "white" if current > 0 else "#ff3333"
	ammo_label.text = "[color=%s]%d[/color] / %d" % [color, current, max_ammo]
