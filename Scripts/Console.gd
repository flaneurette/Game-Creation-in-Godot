extends Panel

@onready var console: MarginContainer = get_parent()
@onready var console_input: LineEdit = $CommandInput
@onready var console_log: RichTextLabel = $Log

var commands: Dictionary = {}

func _ready() -> void:
	# Keep running while the tree is paused (children inherit this).
	console.process_mode = Node.PROCESS_MODE_ALWAYS
	console.visible = false
	console_input.text_submitted.connect(_on_text_submitted)
	_style_input()
	_register_commands()

func _style_input() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0.6)
	normal.set_border_width_all(1)
	normal.border_color = Color(0.7, 0.0, 0.0, 0.6)
	normal.set_corner_radius_all(3)
	normal.content_margin_left = 8
	normal.content_margin_right = 8

	var focused := normal.duplicate() as StyleBoxFlat
	focused.border_color = Color(0.9, 0.1, 0.1, 1.0)  # brighter while typing

	console_input.add_theme_stylebox_override("normal", normal)
	console_input.add_theme_stylebox_override("focus", focused)
	console_input.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	console_input.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.3))
	console_input.add_theme_color_override("caret_color", Color(0.9, 0.1, 0.1))
	console_input.add_theme_font_size_override("font_size", 18)

func _register_commands() -> void:
	commands = {
		"god": _cmd_god,
		"ammo": _cmd_ammo,
		"heal": _cmd_heal,
		"help": _cmd_help,
	}

func _input(event: InputEvent) -> void:
	if GameManager.health <= 0:
		return  # dead: the death screen owns the paused state
	if event is InputEventKey and event.pressed and not event.echo \
			and (event.physical_keycode == KEY_QUOTELEFT or event.is_action_pressed("toggle_console")):
		_toggle_console()
		get_viewport().set_input_as_handled()  # keep ` out of the text field

func _toggle_console() -> void:
	console.visible = not console.visible
	# Pausing stops player movement, shooting and mouse-look while typing.
	get_tree().paused = console.visible
	if console.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		console_input.clear()
		console_input.grab_focus()
	else:
		console_input.release_focus()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func log_line(msg: String) -> void:
	console_log.append_text(msg + "\n")
	print(msg)

func _on_text_submitted(text: String) -> void:
	console_input.clear()
	var parts := text.strip_edges().split(" ", false)
	if parts.is_empty():
		return
	log_line("[color=gray]> %s[/color]" % text)
	var cmd := parts[0].to_lower()
	var args := parts.slice(1)
	if commands.has(cmd):
		commands[cmd].call(args)
	else:
		log_line("[color=red]Unknown command: %s[/color]" % cmd)
	console_input.grab_focus()  # keep typing after Enter

# --- commands ---------------------------------------------------------------
func _cmd_god(_args: Array) -> void:
	GameManager.god_mode = not GameManager.god_mode
	log_line("God mode: %s" % ("ON" if GameManager.god_mode else "OFF"))

func _cmd_ammo(_args: Array) -> void:
	GameManager.bullets = GameManager.MAX_BULLETS
	GameManager.explosives = GameManager.MAX_EXPLOSIVES
	GameManager.knives = GameManager.MAX_KNIVES
	# HUD shows the current weapon's ammo; refresh it with the gun's values.
	EventBus.player_ammo_changed.emit(GameManager.bullets, GameManager.MAX_BULLETS)
	log_line("Ammo refilled.")

func _cmd_heal(_args: Array) -> void:
	GameManager.health = GameManager.MAX_HEALTH
	EventBus.player_health_changed.emit(GameManager.health, GameManager.MAX_HEALTH)
	log_line("Health restored.")

func _cmd_help(_args: Array) -> void:
	log_line("Commands: " + ", ".join(commands.keys()))
