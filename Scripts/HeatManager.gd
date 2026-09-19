extends Node
# heat_manager.gd (listens, doesn't care who fired or why)
func _ready() -> void:
	EventBus.weapon_fired.connect(_on_weapon_fired)

func _on_weapon_fired(pos: Vector3, _name: String) -> void:
	return
	# add_tactical_heat(pos)
