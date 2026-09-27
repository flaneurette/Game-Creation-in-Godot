extends Node3D

@onready var area: Area3D = $Area3D

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.collected_weapon = true
		body.collected_type = 'gun'
		body.current_collectible = self
		visible = false
		GameManager.bullets += 30
		EventBus.player_ammo_changed.emit(30, 30)
