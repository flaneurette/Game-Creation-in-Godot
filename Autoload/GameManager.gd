extends Node

var player_name: String = "Player"
# Game Variables
# ------------------------------------------------------------------------------
# player health
var health: int = 100
# score board
var score: int = 0
# gun bullets
var bullets: int = 30
# grenades, explosives, etc
var explosives: int = 3
# knives wear down after use, decrease by 2
var knives: int = 20

# Max values — used by the HUD to size ammo bars per weapon type.
const MAX_BULLETS: int = 30
const MAX_EXPLOSIVES: int = 3
const MAX_KNIVES: int = 20

func addScore(points: int) -> void:
	score += points

func reset() -> void:
	score = 0

# INPUT MANAGER
# ------------------------------------------------------------------------------
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			# get_tree().quit()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			print("Mouse released.")

# WEAPONS MANAGER
# ------------------------------------------------------------------------------
func weaponUsed(type: String) -> void:
	if(type == 'gun'):
		bullets -= 1
	if(type == 'explosives'):
		explosives -= 1
	if(type == 'knife'):
		knives -= 2

func hasAmmo(type: String) -> bool:
	match type:
		'gun':
			return bullets > 0
		'explosives':
			return explosives > 0
		'knife':
			return knives > 0
	return false

func getAmmoCount(type: String) -> int:
	match type:
		'gun':
			return bullets
		'explosives':
			return explosives
		'knife':
			return knives
	return 0

func getMaxAmmo(type: String) -> int:
	match type:
		'gun':
			return MAX_BULLETS
		'explosives':
			return MAX_EXPLOSIVES
		'knife':
			return MAX_KNIVES
	return 0
