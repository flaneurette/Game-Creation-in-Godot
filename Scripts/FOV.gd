extends Camera3D

@export var base_fov: float = 75.0          # your target FOV for a standard 16:9 screen
@export var reference_aspect: float = 16.0 / 9.0

func _ready():
	keep_aspect = Camera3D.KEEP_WIDTH
	_update_fov()
	get_viewport().size_changed.connect(_update_fov)

func _update_fov():
	var vp_size = get_viewport().get_visible_rect().size
	var aspect = vp_size.x / vp_size.y

	# Scale FOV up only partially as aspect widens, so vertical view
	# doesn't shrink as aggressively as pure Keep Width would cause.
	var widen_factor = clamp(aspect / reference_aspect, 1.0, 2.0)
	fov = base_fov * lerp(1.0, sqrt(widen_factor), 0.7)
