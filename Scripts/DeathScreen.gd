extends CanvasLayer
## Shown when the player dies: covers the screen with a panel and freezes the game.
## Assign the picture in the Inspector (Image) on the DeathScreen node.

@export var image: Texture2D

@onready var image_rect: TextureRect = $Panel/Image

func _ready() -> void:
	# Keep running while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	image_rect.texture = image
	EventBus.player_died.connect(_on_player_died)

func _on_player_died() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
