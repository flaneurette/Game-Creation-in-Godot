# res://Autoload/event_bus.gd
extends Node

signal player_died
signal game_state_changed(new_state: String)

signal weapon_fired(position: Vector3, weapon_name: String)
signal player_damaged(amount: int, source: Node)
signal enemy_killed(enemy: Node, was_witnessed: bool)
signal player_health_changed(current: int)
signal player_ammo_changed(current: int, max_ammo: int)
signal weapon_switched(type: String)
signal enemy_died(enemy)

# Usage in scripts:
# emitter
# EventBus.enemy_killed.emit(self)

# listener (in any scene)
#func _ready():
#    EventBus.player_died.connect(_on_player_died)

# func _on_player_died():
#    print("game over!")
