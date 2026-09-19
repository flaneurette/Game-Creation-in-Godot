extends Sprite2D

var noise: FastNoiseLite
var noise_texture: NoiseTexture2D

func _ready():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.02
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5

	noise_texture = NoiseTexture2D.new()
	noise_texture.width = 512
	noise_texture.height = 512
	noise_texture.noise = noise
	noise_texture.seamless = true  # important for tiling/scrolling

	texture = noise_texture
	
func _process(delta):
	noise.offset += Vector3(delta * 5.0, 0, 0)  # drift clouds sideways
