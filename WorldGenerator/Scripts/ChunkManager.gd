class_name ChunkManager extends Node

const CACHE_CELLS = 0
const CACHE_TIMESTAMP = 1
const CACHE_OBJECTS = 2

const TileCategory = {
	EMPTY = -1,
	NON_TERRAIN = -2,
	ERROR = -3
}

var loaded_chunks = {}
var cached_chunks = {}
var chunk_queue = []
var chunk_objects = {}
var object_pool = {}
var world_generator: WorldGenerator
var ground_layer: TileMapLayer
var settings = {}
var biomes = []
var visible_chunks = {}

var player_direction: Vector2 = Vector2.ZERO
var last_player_chunk: Vector2i = Vector2i.ZERO

# Словарь для хранения статистики времени выполнения
var profiling_data = {
	"generate_chunk": {"total": 0.0, "count": 0, "stages": {}},
	"apply_chunk": {"total": 0.0, "count": 0},
	"update_chunks": {"total": 0.0, "count": 0},
	"update_chunk_borders": {"total": 0.0, "count": 0},
	"load_next_chunk": {"total": 0.0, "count": 0},
	"cache_chunk": {"total": 0.0, "count": 0.0},
	"clear_chunk": {"total": 0.0, "count": 0},
	"set_cells": {"total": 0.0, "count": 0}
}

func _ready():
	# Инициализация стадий для generate_chunk
	profiling_data["generate_chunk"]["stages"] = {
		"noise": {"total": 0.0, "count": 0},
		"biomes": {"total": 0.0, "count": 0},
		"apply": {"total": 0.0, "count": 0},
		"objects": {"total": 0.0, "count": 0}
	}

func initialize(wg: WorldGenerator, gl: TileMapLayer, gen_settings: Dictionary, biome_settings: BiomeSettings):
	world_generator = wg
	ground_layer = gl
	settings = gen_settings
	biomes = biome_settings.biomes
	print(biomes)
	biomes.sort_custom(func(a, b): return a[2] < b[2])

func find_biome(noise_value: float) -> int:
	var left = 0
	var right = biomes.size() - 1
	while left <= right:
		var mid = (left + right) / 2
		if noise_value >= biomes[mid][2] and noise_value <= biomes[mid][3]:
			return biomes[mid][0]
		elif noise_value < biomes[mid][2]:
			right = mid - 1
		else:
			left = mid + 1
	return 0 # Резервный террейн

func update_player_direction(current_chunk: Vector2i):
	if last_player_chunk != current_chunk:
		player_direction = Vector2((current_chunk - last_player_chunk)).normalized()
		last_player_chunk = current_chunk

func calculate_distance(chunk_pos: Vector2i, player_chunk: Vector2i) -> int:
	return abs(chunk_pos.x - player_chunk.x) + abs(chunk_pos.y - player_chunk.y)

func update_chunks(player_chunk: Vector2i):
	var start_time = Time.get_ticks_usec()
	
	update_player_direction(player_chunk)
	var render_distance = settings["render_distance"]
	var new_visible_chunks = {}
	
	# Используем массив вместо словаря для оптимизации
	var chunks_to_check = []
	for x in range(player_chunk.x - render_distance, player_chunk.x + render_distance + 1):
		for y in range(player_chunk.y - render_distance, player_chunk.y + render_distance + 1):
			var chunk_pos = Vector2i(x, y)
			chunks_to_check.append(chunk_pos)
			new_visible_chunks[chunk_pos] = true
	
	for chunk_pos in chunks_to_check:
		if not loaded_chunks.has(chunk_pos) and not chunk_queue.has(chunk_pos):
			if cached_chunks.has(chunk_pos):
				restore_chunk(chunk_pos)
			else:
				chunk_queue.append(chunk_pos)
	
	# Сортировка только если очередь большая
	if chunk_queue.size() > 10:
		chunk_queue.sort_custom(func(a, b): 
			var dist_a = calculate_distance(a, player_chunk)
			var dist_b = calculate_distance(b, player_chunk)
			return dist_a < dist_b)
	
	for chunk_pos in loaded_chunks.keys():
		if not new_visible_chunks.has(chunk_pos):
			cache_chunk(chunk_pos)
			loaded_chunks.erase(chunk_pos)
	
	visible_chunks = new_visible_chunks
	
	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["update_chunks"]["total"] += duration
	profiling_data["update_chunks"]["count"] += 1
	
func load_next_chunk():
	var start_time = Time.get_ticks_usec()
	if chunk_queue.is_empty():
		return
	var chunk_pos = chunk_queue.pop_front()
	generate_chunk(chunk_pos)
	
	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["load_next_chunk"]["total"] += duration
	profiling_data["load_next_chunk"]["count"] += 1

func generate_chunk(chunk_pos: Vector2i) -> void:
	var start_time_total = Time.get_ticks_usec()
	
	var chunk_size = settings["chunk_size"]
	var cells_by_terrain = {}
	
	var noise_values = world_generator.noise_manager.get_chunk_noise(chunk_pos, chunk_size)
	
	for biome in biomes:
		cells_by_terrain[biome[0]] = []
	
	for pos in noise_values.keys():
		var noise_value = noise_values[pos]
		var selected_terrain = find_biome(noise_value)
		cells_by_terrain[selected_terrain].append(pos)
	
	apply_chunk(chunk_pos, cells_by_terrain)
	
	# Спавн объектов после генерации чанка
	var min_pos = chunk_pos * chunk_size
	var max_pos = min_pos + Vector2i(chunk_size.x - 1, chunk_size.y - 1)
	world_generator.object_spawner.generate_objects_in_area(min_pos, max_pos, false)
	world_generator.object_spawner.spawn_structures_in_area(min_pos, max_pos)
	var total_duration = (Time.get_ticks_usec() - start_time_total) / 1000.0
	profiling_data["generate_chunk"]["total"] += total_duration
	profiling_data["generate_chunk"]["count"] += 1

func set_cells(tm: TileMapLayer, coords: Array, type: int) -> bool:
	var start_time = Time.get_ticks_usec()
	if !tm or !tm.tile_set or type < TileCategory.EMPTY:
		return false
	
	var result = BetterTerrain.set_cells(tm, coords, type)
	if result and type != TileCategory.EMPTY:
		BetterTerrain.update_terrain_cells(tm, coords, true)
	
	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["set_cells"]["total"] += duration
	profiling_data["set_cells"]["count"] += 1
	return result

func apply_chunk(chunk_pos: Vector2i, cells_by_terrain: Dictionary):
	var start_time = Time.get_ticks_usec()
	
	var all_cells = []
	for terrain_index in cells_by_terrain.keys():
		if cells_by_terrain[terrain_index].size() > 0:
			all_cells.append_array(cells_by_terrain[terrain_index])
	
	# Один вызов set_cells для всех ячеек
	#set_cells(ground_layer, all_cells, TileCategory.EMPTY) # Сначала очищаем
	for terrain_index in cells_by_terrain.keys():
		if cells_by_terrain[terrain_index].size() > 0:
			set_cells(ground_layer, cells_by_terrain[terrain_index], terrain_index)
	
	# Обновляем террейн один раз для всех ячеек
	BetterTerrain.update_terrain_cells(ground_layer, all_cells, true)
	
	loaded_chunks[chunk_pos] = true
	
	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["apply_chunk"]["total"] += duration
	profiling_data["apply_chunk"]["count"] += 1

func update_chunk_borders(chunk_pos: Vector2i):
	var start_time = Time.get_ticks_usec()
	
	var chunk_size = settings["chunk_size"]
	var border_cells = {}
	for biome in biomes:
		border_cells[biome[0]] = []
	
	var border_positions = get_border_positions(chunk_pos, chunk_size)
	border_positions.append_array(get_neighbor_border_positions(chunk_pos, chunk_size))
	
	for pos in border_positions:
		update_border_cell(pos, border_cells)
	
	var chunk_cells = []
	for terrain_index in border_cells.keys():
		if border_cells[terrain_index].size() > 0:
			chunk_cells.append_array(border_cells[terrain_index])
			set_cells(ground_layer, border_cells[terrain_index], terrain_index)
	
	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["update_chunk_borders"]["total"] += duration
	profiling_data["update_chunk_borders"]["count"] += 1

func clear_chunk(chunk_pos: Vector2i):
	var start_time = Time.get_ticks_usec()
	
	var chunk_size = settings["chunk_size"]
	var start_pos = chunk_pos * chunk_size
	var cells_to_clear = []
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			cells_to_clear.append(start_pos + Vector2i(x, y))
	
	set_cells(ground_layer, cells_to_clear, TileCategory.EMPTY)
	
	if chunk_objects.has(chunk_pos):
		for obj in chunk_objects[chunk_pos]:
			if is_instance_valid(obj):
				var scene_path = obj.scene_file_path
				if not object_pool.has(scene_path):
					object_pool[scene_path] = []
				object_pool[scene_path].append(obj)
				obj.get_parent().remove_child(obj)
		chunk_objects.erase(chunk_pos)
	
	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["clear_chunk"]["total"] += duration
	profiling_data["clear_chunk"]["count"] += 1

func cache_chunk(chunk_pos: Vector2i):
	var start_time = Time.get_ticks_usec()
	
	var chunk_size = settings["chunk_size"]
	var start_pos = chunk_pos * chunk_size
	var cells_by_terrain = {}
	for biome in biomes:
		cells_by_terrain[biome[0]] = []

	# Сохраняем биомы на основе шума
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			var pos = start_pos + Vector2i(x, y)
			var noise_value = world_generator.noise_manager.get_cached_noise(pos)
			var selected_terrain = 0  # Биом по умолчанию
			for biome in biomes:
				if noise_value >= biome[2] and noise_value <= biome[3]:
					selected_terrain = biome[0]
					break
			cells_by_terrain[selected_terrain].append(pos)

	var object_data = []
	if chunk_objects.has(chunk_pos):
		for obj in chunk_objects[chunk_pos]:
			if is_instance_valid(obj):
				var scene_path = obj.scene_file_path
				var position = obj.global_position
				object_data.append(ObjectData.new(scene_path, position))
				if not object_pool.has(scene_path):
					object_pool[scene_path] = []
				object_pool[scene_path].append(obj)
				obj.get_parent().remove_child(obj)
		chunk_objects.erase(chunk_pos)

	cached_chunks[chunk_pos] = [cells_by_terrain, Time.get_ticks_msec() / 1000.0, object_data]
	clear_chunk(chunk_pos)
	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["cache_chunk"]["total"] += duration
	profiling_data["cache_chunk"]["count"] += 1

func restore_chunk(chunk_pos: Vector2i):
	var start_time = Time.get_ticks_usec()
	
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
	
	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["restore_chunk"] = profiling_data.get("restore_chunk", {"total": 0.0, "count": 0})
	profiling_data["restore_chunk"]["total"] += duration
	profiling_data["restore_chunk"]["count"] += 1

func get_border_positions(chunk_pos: Vector2i, chunk_size: Vector2i) -> Array:
	var start_time = Time.get_ticks_usec()
	var start_pos = chunk_pos * chunk_size
	var positions = []
	for x in range(chunk_size.x):
		positions.append(start_pos + Vector2i(x, 0))
		positions.append(start_pos + Vector2i(x, chunk_size.y - 1))
	for y in range(1, chunk_size.y - 1):
		positions.append(start_pos + Vector2i(0, y))
		positions.append(start_pos + Vector2i(chunk_size.x - 1, y))
	
	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["get_border_positions"] = profiling_data.get("get_border_positions", {"total": 0.0, "count": 0})
	profiling_data["get_border_positions"]["total"] += duration
	profiling_data["get_border_positions"]["count"] += 1
	return positions

func get_neighbor_border_positions(chunk_pos: Vector2i, chunk_size: Vector2i) -> Array:
	var start_time = Time.get_ticks_usec()
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
	
	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["get_neighbor_border_positions"] = profiling_data.get("get_neighbor_border_positions", {"total": 0.0, "count": 0})
	profiling_data["get_neighbor_border_positions"]["total"] += duration
	profiling_data["get_neighbor_border_positions"]["count"] += 1
	return positions

func update_border_cell(pos: Vector2i, border_cells: Dictionary):
	var start_time = Time.get_ticks_usec()
	
	var noise_value = world_generator.noise_manager.get_cached_noise(pos)
	var selected_terrain = 0
	for biome in biomes:
		if noise_value >= biome[2] and noise_value <= biome[3]:
			selected_terrain = biome[0]
			break
	border_cells[selected_terrain].append(pos)
	
	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["update_border_cell"] = profiling_data.get("update_border_cell", {"total": 0.0, "count": 0})
	profiling_data["update_border_cell"]["total"] += duration
	profiling_data["update_border_cell"]["count"] += 1

func get_current_bounds() -> Array[Vector2]:
	var start_time = Time.get_ticks_usec()
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
	var bounds: Array[Vector2] = [
		Vector2(min_x * tile_size.x, min_y * tile_size.y),
		Vector2(max_x * tile_size.x, max_y * tile_size.y)
	]
	
	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["get_current_bounds"] = profiling_data.get("get_current_bounds", {"total": 0.0, "count": 0})
	profiling_data["get_current_bounds"]["total"] += duration
	profiling_data["get_current_bounds"]["count"] += 1
	return bounds

func pregenerate_chunks(player_chunk: Vector2i, pregen_distance: int):
	var start_time = Time.get_ticks_usec()
	var render_distance = settings["render_distance"]
	for x in range(player_chunk.x - pregen_distance, player_chunk.x + pregen_distance + 1):
		for y in range(player_chunk.y - pregen_distance, player_chunk.y + pregen_distance + 1):
			var chunk_pos = Vector2i(x, y)
			var distance = abs(chunk_pos.x - player_chunk.x) + abs(chunk_pos.y - player_chunk.y)
			if distance > render_distance and not cached_chunks.has(chunk_pos) and not chunk_queue.has(chunk_pos):
				chunk_queue.append(chunk_pos)
	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["pregenerate_chunks"] = profiling_data.get("pregenerate_chunks", {"total": 0.0, "count": 0})
	profiling_data["pregenerate_chunks"]["total"] += duration
	profiling_data["pregenerate_chunks"]["count"] += 1

# Функция для вывода статистики профилирования
func print_profiling_stats():
	for func_name in profiling_data.keys():
		var data = profiling_data[func_name]
		var avg_time = data["total"] / max(data["count"], 1)
		print("Function: %s, Avg Time: %.3f ms, Calls: %d" % [func_name, avg_time, data["count"]])
		if func_name == "generate_chunk" and data["stages"]:
			for stage_name in data["stages"].keys():
				var stage_data = data["stages"][stage_name]
				var stage_avg = stage_data["total"] / max(stage_data["count"], 1)
				print("  Stage: %s, Avg Time: %.3f ms, Calls: %d" % [stage_name, stage_avg, stage_data["count"]])

# Вызывать периодически для вывода статистики (например, каждые 10 секунд)
func _process(delta):
	if Time.get_ticks_msec() % 10000 < delta * 1000: # Каждые 10 секунд
		print_profiling_stats()
