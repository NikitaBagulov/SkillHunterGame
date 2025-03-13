class_name NoiseManager extends Node

var noise = FastNoiseLite.new()
var density_noise = FastNoiseLite.new()
var noise_cache = {}
var settings = {}

func initialize(gen_settings: Dictionary):
	settings = gen_settings
	noise.noise_type = settings["noise_type"]
	noise.seed = settings["noise_seed"] if settings["noise_seed"] != 0 else randi()
	noise.frequency = settings["noise_frequency"]
	noise.fractal_octaves = settings["noise_octaves"]
	
	density_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	density_noise.seed = noise.seed + 1
	density_noise.frequency = settings["density_noise_frequency"]
	density_noise.fractal_octaves = 3

func get_cached_noise(pos: Vector2i) -> float:
	if noise_cache.has(pos):
		return noise_cache[pos]
	var noise_pos = Vector2(pos.x, pos.y) * settings["tile_scale"] + settings["noise_offset"]
	var value = noise.get_noise_2d(noise_pos.x, noise_pos.y)
	noise_cache[pos] = value
	return value

func get_density_noise(pos: Vector2) -> float:
	return (density_noise.get_noise_2d(pos.x, pos.y) + 1.0) / 2.0
