class_name ChunkManager extends Node

const CACHE_CELLS = 0
const CACHE_TIMESTAMP = 1
const CACHE_OBJECTS = 2

var loaded_chunks = {}
var cached_chunks = {}
var chunk_queue = []
var chunk_objects = {}
var object_pool = {}
var world_generator: WorldGenerator
var ground_layer: Node2D
var settings = {}
var biomes = []

func initialize(wg: WorldGenerator, gl: Node2D, gen_settings: Dictionary, biome_settings: BiomeSettings):
	world_generator = wg
	ground_layer = gl
	settings = gen_settings
	biomes = biome_settings.biomes

func update_chunks(player_chunk: Vector2i):
	var new_chunks = {}
	var render_distance = settings["render_distance"]
	for x in range(player_chunk.x - render_distance, player_chunk.x + render_distance + 1):
		for y in range(player_chunk.y - render_distance, player_chunk.y + render_distance + 1):
			var chunk_pos = Vector2i(x, y)
			new_chunks[chunk_pos] = true
			if not loaded_chunks.has(chunk_pos) and not chunk_queue.has(chunk_pos):
				if cached_chunks.has(chunk_pos):
					restore_chunk(chunk_pos)
				else:
					chunk_queue.append(chunk_pos)
	
	if chunk_queue.size() > 100:
		chunk_queue.resize(50)
	
	var current_time = Time.get_ticks_msec() / 1000.0
	for chunk_pos in loaded_chunks.keys():
		if not new_chunks.has(chunk_pos):
			cache_chunk(chunk_pos)
	
	var to_remove = []
	for chunk_pos in cached_chunks.keys():
		if current_time - cached_chunks[chunk_pos][CACHE_TIMESTAMP] > settings["chunk_cache_time"]:
			to_remove.append(chunk_pos)
	for chunk_pos in to_remove:
		clear_chunk(chunk_pos)
		cached_chunks.erase(chunk_pos)
	
	loaded_chunks = new_chunks

func load_next_chunk():
	if chunk_queue.is_empty():
		return
	var chunk_pos = chunk_queue.pop_front()
	generate_chunk(chunk_pos)

func generate_chunk(chunk_pos: Vector2i):
	var chunk_size = settings["chunk_size"]
	var start_pos = chunk_pos * chunk_size
	var cells_by_terrain = {}
	var noise_values = {}
	
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			var pos = start_pos + Vector2i(x, y)
			noise_values[pos] = world_generator.noise_manager.get_cached_noise(pos)
	
	for biome in biomes:
		cells_by_terrain[biome[0]] = []
	
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			var pos = start_pos + Vector2i(x, y)
			var noise_value = noise_values[pos]
			var selected_terrain = -1
			for biome in biomes:
				if noise_value >= biome[2] and noise_value <= biome[3]:
					selected_terrain = biome[0]
					break
			if selected_terrain != -1:
				cells_by_terrain[selected_terrain].append(pos)
	
	apply_chunk(chunk_pos, cells_by_terrain)
	world_generator.object_spawner.generate_objects(chunk_pos)

func apply_chunk(chunk_pos: Vector2i, cells_by_terrain: Dictionary):
	for terrain_index in cells_by_terrain.keys():
		if cells_by_terrain[terrain_index].size() > 0:
			ground_layer.set_cells_terrain_connect(cells_by_terrain[terrain_index], 0, terrain_index, false)
			ground_layer.set_cells_terrain_connect(cells_by_terrain[terrain_index], 0, terrain_index, false)
	update_chunk_borders(chunk_pos)

func cache_chunk(chunk_pos: Vector2i):
	var chunk_size = settings["chunk_size"]
	var start_pos = chunk_pos * chunk_size
	var cells_by_terrain = {}
	for biome in biomes:
		cells_by_terrain[biome[0]] = []
	
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			var pos = start_pos + Vector2i(x, y)
			var tile_data = ground_layer.get_cell_tile_data(pos)
			if tile_data:
				cells_by_terrain[tile_data.terrain].append(pos)
	
	var object_data = []
	if chunk_objects.has(chunk_pos):
		for obj in chunk_objects[chunk_pos]:
			var scene_path = obj.scene_file_path
			if not object_pool.has(scene_path):
				object_pool[scene_path] = []
			object_pool[scene_path].append(obj)
			obj.get_parent().remove_child(obj)
			object_data.append(ObjectData.new(scene_path, obj.global_position))
		chunk_objects.erase(chunk_pos)
	
	cached_chunks[chunk_pos] = [cells_by_terrain, Time.get_ticks_msec() / 1000.0, object_data]
	clear_chunk(chunk_pos)

func restore_chunk(chunk_pos: Vector2i):
	var cells_by_terrain = cached_chunks[chunk_pos][CACHE_CELLS]
	var object_data = cached_chunks[chunk_pos][CACHE_OBJECTS]
	apply_chunk(chunk_pos, cells_by_terrain)
	cached_chunks.erase(chunk_pos)
	
	chunk_objects[chunk_pos] = []
	for data in object_data:
		var scene_path = data.scene_path
		var instance = null
		if object_pool.has(scene_path) and not object_pool[scene_path].is_empty():
			instance = object_pool[scene_path].pop_back()
			instance.global_position = data.position
		else:
			var scene = load(scene_path)
			if scene:
				instance = scene.instantiate()
				instance.global_position = data.position
		if instance:
			world_generator.objects_node.add_child(instance)
			chunk_objects[chunk_pos].append(instance)

func clear_chunk(chunk_pos: Vector2i):
	var chunk_size = settings["chunk_size"]
	var start_pos = chunk_pos * chunk_size
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			ground_layer.erase_cell(start_pos + Vector2i(x, y))
	
	if chunk_objects.has(chunk_pos):
		for obj in chunk_objects[chunk_pos]:
			obj.queue_free()
		chunk_objects.erase(chunk_pos)

func update_chunk_borders(chunk_pos: Vector2i):
	var chunk_size = settings["chunk_size"]
	var border_cells = {}
	for biome in biomes:
		border_cells[biome[0]] = []
	
	var border_positions = get_border_positions(chunk_pos, chunk_size)
	border_positions.append_array(get_neighbor_border_positions(chunk_pos, chunk_size))
	
	for pos in border_positions:
		update_border_cell(pos, border_cells)
	
	for terrain_index in border_cells.keys():
		if border_cells[terrain_index].size() > 0:
			ground_layer.set_cells_terrain_connect(border_cells[terrain_index], 0, terrain_index, false)
			ground_layer.set_cells_terrain_connect(border_cells[terrain_index], 0, terrain_index, false)

func get_border_positions(chunk_pos: Vector2i, chunk_size: Vector2i) -> Array:
	var start_pos = chunk_pos * chunk_size
	var positions = []
	for x in range(chunk_size.x):
		positions.append(start_pos + Vector2i(x, 0))
		positions.append(start_pos + Vector2i(x, chunk_size.y - 1))
	for y in range(1, chunk_size.y - 1):
		positions.append(start_pos + Vector2i(0, y))
		positions.append(start_pos + Vector2i(chunk_size.x - 1, y))
	return positions

func get_neighbor_border_positions(chunk_pos: Vector2i, chunk_size: Vector2i) -> Array:
	var positions = []
	var neighbors = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for neighbor in neighbors:
		var neighbor_chunk = chunk_pos + neighbor
		if loaded_chunks.has(neighbor_chunk):
			var neighbor_start = neighbor_chunk * chunk_size
			if neighbor.x == -1:
				for y in range(chunk_size.y):
					positions.append(neighbor_start + Vector2i(chunk_size.x - 1, y))
			elif neighbor.x == 1:
				for y in range(chunk_size.y):
					positions.append(neighbor_start + Vector2i(0, y))
			elif neighbor.y == -1:
				for x in range(chunk_size.x):
					positions.append(neighbor_start + Vector2i(x, chunk_size.y - 1))
			elif neighbor.y == 1:
				for x in range(chunk_size.x):
					positions.append(neighbor_start + Vector2i(x, 0))
	return positions

func update_border_cell(pos: Vector2i, border_cells: Dictionary):
	var noise_value = world_generator.noise_manager.get_cached_noise(pos)
	var selected_terrain = 0
	for biome in biomes:
		if noise_value >= biome[2] and noise_value <= biome[3]:
			selected_terrain = biome[0]
			break
	border_cells[selected_terrain].append(pos)

func get_current_bounds() -> Array[Vector2]:
	if loaded_chunks.is_empty():
		return [Vector2.ZERO, Vector2.ZERO]
	
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	for chunk_pos in loaded_chunks.keys():
		var chunk_start = chunk_pos * settings["chunk_size"]
		var chunk_end = chunk_start + settings["chunk_size"]
		min_x = min(min_x, chunk_start.x)
		min_y = min(min_y, chunk_start.y)
		max_x = max(max_x, chunk_end.x)
		max_y = max(max_y, chunk_end.y)
	
	var tile_size = world_generator.tile_set.tile_size * settings["tile_scale"]
	return [
		Vector2(min_x * tile_size.x, min_y * tile_size.y),
		Vector2(max_x * tile_size.x, max_y * tile_size.y)
	]
