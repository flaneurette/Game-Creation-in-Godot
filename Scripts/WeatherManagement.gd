extends Node3D

@onready var multimesh_instance: MultiMeshInstance3D = $Weather3D
@export var follow_target: Node3D

var raindice = [0,1,1,1,1]
var letitrain = raindice.pick_random()

var numbers = [1000, 10000, 6000, 8000, 12000, 1500, 2000, 5000, 4000]
var random_number = numbers.pick_random()

var height := 60.0
var drop_count = int(random_number * height / 10)
var fall_speed := 12.0
var area_size := Vector2(80, 80)
var floor_offset := 1.0

var speeds: Array = []

func _ready():
	
	if(letitrain == 1):
		
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = BoxMesh.new()
		mm.mesh.size = Vector3(0.025, 0.6, 0.025)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.318, 0.318, 0.318, 0.831)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = Color(0.424, 0.537, 0.651, 0.161)
		mat.emission_energy_multiplier = 0.5
		mm.mesh.surface_set_material(0, mat)

		mm.instance_count = drop_count
		multimesh_instance.multimesh = mm

		for i in drop_count:
			var pos = Vector3(
				randf_range(-area_size.x / 2, area_size.x / 2),
				randf_range(-floor_offset, height),
				randf_range(-area_size.y / 2, area_size.y / 2)
			)
			mm.set_instance_transform(i, Transform3D(Basis(), pos))
			speeds.append(randf_range(fall_speed * 0.7, fall_speed * 1.3))

func _process(delta):
	
	if(letitrain == 1):
		
		if multimesh_instance.multimesh == null or follow_target == null:
			return

		var mm := multimesh_instance.multimesh
		var origin = follow_target.global_transform.origin

		for i in drop_count:
			var t = mm.get_instance_transform(i)
			t.origin.y -= speeds[i] * delta
			if t.origin.y < origin.y - floor_offset:
				t.origin.y = origin.y + height
				t.origin.x = origin.x + randf_range(-area_size.x / 2, area_size.x / 2)
				t.origin.z = origin.z + randf_range(-area_size.y / 2, area_size.y / 2)
			# Wrap x/z into the box around the player so the field tracks movement
			# immediately, not only when a drop respawns.
			t.origin.x = origin.x + posmod(t.origin.x - origin.x + area_size.x / 2, area_size.x) - area_size.x / 2
			t.origin.z = origin.z + posmod(t.origin.z - origin.z + area_size.y / 2, area_size.y) - area_size.y / 2
			mm.set_instance_transform(i, t)
