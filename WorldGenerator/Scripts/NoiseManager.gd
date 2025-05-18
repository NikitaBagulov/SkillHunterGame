class_name NoiseManager extends Node

var noise = FastNoiseLite.new()
var density_noise = FastNoiseLite.new()
var noise_cache = {}
var settings = {}

var global_min_noise = INF
var global_max_noise = -INF

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

func get_chunk_noise(chunk_pos: Vector2i, chunk_size: Vector2i) -> Dictionary:
	var noise_values = {}
	var start_pos = chunk_pos * chunk_size
	var min_noise = INF
	var max_noise = -INF
	
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			var pos = start_pos + Vector2i(x, y)
			var noise_val = get_cached_noise(pos)
			noise_values[pos] = noise_val
			min_noise = min(min_noise, noise_val)
			max_noise = max(max_noise, noise_val)
	
	global_min_noise = min(global_min_noise, min_noise)
	global_max_noise = max(global_max_noise, max_noise)
	print("Chunk ", chunk_pos, " noise range: [", min_noise, ", ", max_noise, "]")
	print("Global noise range: [", global_min_noise, ", ", global_max_noise, "]")
	
	return noise_values

func get_density_noise(pos: Vector2) -> float:
	return (density_noise.get_noise_2d(pos.x, pos.y) + 1.0) / 2.0
