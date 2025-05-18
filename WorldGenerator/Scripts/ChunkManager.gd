class_name ChunkManager extends Node

const CACHE_CELLS = 0
const CACHE_TIMESTAMP = 1
const CACHE_OBJECTS = 2
const CACHE_SPAWN_POSITIONS = 3  # Новый индекс для позиций спавна

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

var global_object_positions: Dictionary = {}  # key: Vector2i(chunk_pos), value: Set of Vector2i

var player_direction: Vector2 = Vector2.ZERO
var last_player_chunk: Vector2i = Vector2i.ZERO

var generation_thread := Thread.new()
var thread_result := {}

var profiling_data = {
	"generate_chunk": {"total": 0.0, "count": 0, "stages": {}},
	"apply_chunk": {"total": 0.0, "count": 0},
	"spawn_objects": {"total": 0.0, "count": 0},  # Новая метрика для спавна
	"update_chunks": {"total": 0.0, "count": 0},
	"update_chunk_borders": {"total": 0.0, "count": 0},
	"load_next_chunk": {"total": 0.0, "count": 0},
	"cache_chunk": {"total": 0.0, "count": 0.0},
	"clear_chunk": {"total": 0.0, "count": 0},
	"set_cells": {"total": 0.0, "count": 0}
}

func _ready():
	profiling_data["generate_chunk"]["stages"] = {
		"noise": {"total": 0.0, "count": 0},
		"biomes": {"total": 0.0, "count": 0},
		"apply": {"total": 0.0, "count": 0}
	}

func initialize(wg: WorldGenerator, gl: TileMapLayer, gen_settings: Dictionary, biome_settings: BiomeSettings):
	world_generator = wg
	ground_layer = gl
	settings = gen_settings
	biomes = biome_settings.biomes
	print("Инициализация ChunkManager: biomes=", biomes)
	for biome in biomes:
		if biome.size() < 5:
			print("Ошибка: Некорректный формат биома: ", biome)
		else:
			print("Биом: ", biome[1], ", terrain_index=", biome[0], ", range=[", biome[2], ", ", biome[3], "]")

func find_biome(noise_value: float) -> int:
	for biome in biomes:
		var terrain_index = biome[0]
		var biome_name = biome[1]
		var min_noise = biome[2]
		var max_noise = biome[3]
		if noise_value >= min_noise and noise_value <= max_noise:
			print("find_biome: noise_value=", noise_value, ", выбрано '", biome_name, "' (terrain_index=", terrain_index, ")")
			return terrain_index
	print("find_biome: noise_value=", noise_value, " не соответствует, возвращаем 0 (Grass)")
	return 0

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

	for x in range(player_chunk.x - render_distance, player_chunk.x + render_distance + 1):
		for y in range(player_chunk.y - render_distance, player_chunk.y + render_distance + 1):
			var chunk_pos = Vector2i(x, y)
			new_visible_chunks[chunk_pos] = true
			if not loaded_chunks.has(chunk_pos) and not chunk_queue.has(chunk_pos):
				if cached_chunks.has(chunk_pos):
					restore_chunk(chunk_pos)
				else:
					chunk_queue.append(chunk_pos)

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
	var start_time = Time.get_ticks_usec()
	var chunk_size = settings["chunk_size"]
	var cells_by_terrain = {}
	var object_positions = []

	# Инициализируем клетки по биомам
	for biome in biomes:
		cells_by_terrain[biome[0]] = []

	# Если чанк уже есть в кэше, просто восстанавливаем его
	if cached_chunks.has(chunk_pos):
		restore_chunk(chunk_pos)
		return

	# Генерация шума и определение биомов
	var biome_counts = {}
	var start_pos = chunk_pos * chunk_size
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			var pos = start_pos + Vector2i(x, y)
			var biome_name = world_generator.object_spawner.get_biome_at_position(pos)
			if biome_name == "":
				print("Ошибка: Пустой биом для позиции ", pos)
				biome_name = "Grass"  # Запасной вариант
			var terrain_index = biomes.filter(func(b): return b[1] == biome_name)[0][0]
			cells_by_terrain[terrain_index].append(pos)
			biome_counts[biome_name] = biome_counts.get(biome_name, 0) + 1
			if randf() < 0.8 and world_generator.object_spawner.is_valid_spawn_position(pos):
				object_positions.append({"position": pos, "biome": biome_name})

	# Отладка: выводим распределение биомов
	print("Чанк ", chunk_pos, " biome_counts: ", biome_counts)

	# Определяем доминирующий биом
	var dominant_biome = "Grass"
	var max_count = 0
	for biome_name in biome_counts:
		if biome_counts[biome_name] > max_count:
			max_count = biome_counts[biome_name]
			dominant_biome = biome_name
		elif biome_counts[biome_name] == max_count:
			var current_index = biomes.filter(func(b): return b[1] == biome_name)[0][0]
			var dominant_index = biomes.filter(func(b): return b[1] == dominant_biome)[0][0]
			if current_index < dominant_index:
				dominant_biome = biome_name
				max_count = biome_counts[biome_name]
	print("Чанк ", chunk_pos, " доминирующий биом: ", dominant_biome, " с количеством клеток: ", max_count)

	# Применяем клетки к тайловой карте
	apply_chunk(chunk_pos, cells_by_terrain)

	# Сохраняем данные в кэш
	cached_chunks[chunk_pos] = [
		cells_by_terrain,
		Time.get_ticks_msec() / 1000.0,
		[],  # Пустой список объектов, заполнится при кэшировании
		object_positions  # Сохраняем позиции спавна
	]

	# Спавним объекты только для нового чанка
	var min_pos = chunk_pos * chunk_size
	var max_pos = min_pos + chunk_size - Vector2i(1, 1)
	world_generator.object_spawner.spawn_in_chunk(dominant_biome, object_positions, min_pos, max_pos, chunk_pos)

	var total_duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["generate_chunk"]["total"] += total_duration
	profiling_data["generate_chunk"]["count"] += 1

func spawn_objects_in_chunk(chunk_pos: Vector2i) -> void:
	var start_time = Time.get_ticks_usec()
	if not cached_chunks.has(chunk_pos):
		print("Ошибка: Чанк ", chunk_pos, " не найден в cached_chunks")
		return

	var object_positions = cached_chunks[chunk_pos][CACHE_SPAWN_POSITIONS]
	if object_positions.is_empty():
		print("Чанк ", chunk_pos, ": нет позиций для спавна")
		return

	if object_positions.size() > 5:
		object_positions.shuffle()
		object_positions.resize(5)
		print("Чанк ", chunk_pos, ": ограничено до 5 позиций: ", object_positions)

	var positions_by_biome = {}
	for obj_data in object_positions:
		var biome_name = obj_data["biome"]
		if not positions_by_biome.has(biome_name):
			positions_by_biome[biome_name] = []
		positions_by_biome[biome_name].append(obj_data["position"])

	var chunk_size = settings["chunk_size"]
	var min_pos = chunk_pos * chunk_size
	var max_pos = min_pos + chunk_size - Vector2i(1, 1)
	for biome_name in positions_by_biome.keys():
		var positions = positions_by_biome[biome_name]
		if not positions.is_empty():
			print("Спавн для биома ", biome_name, " с позициями: ", positions)
			world_generator.object_spawner.spawn_in_chunk(biome_name, positions, min_pos, max_pos, chunk_pos)

	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["spawn_objects"]["total"] += duration
	profiling_data["spawn_objects"]["count"] += 1

func choose_spawn_type() -> String:
	var types = ["objects", "enemies"]
	if not world_generator.object_spawner.boss_spawned:
		types.append("boss")
	
	var weights = []
	for type in types:
		if type == "objects" or type == "enemies":
			weights.append(0.4)
		else:
			weights.append(0.2)
	
	var rand = randf()
	var cumulative = 0.0
	for i in range(types.size()):
		cumulative += weights[i]
		if rand < cumulative:
			return types[i]
	return types[0]

func create_object_instance(pos: Vector2i, biome_name: String) -> Node2D:
	var biome_settings = world_generator.biome_settings
	for object_resource in biome_settings.object_resources:
		if object_resource.biome == biome_name and randf() < object_resource.probability:
			var scene = object_resource.scenes[randi() % object_resource.scenes.size()]
			var instance = scene.instantiate()
			return instance
	return null

func set_cells(tm: TileMapLayer, coords: Array, type: int) -> bool:
	var start_time = Time.get_ticks_usec()
	if !tm or !tm.tile_set or type < TileCategory.EMPTY:
		return false
	
	var result = BetterTerrain.set_cells(tm, coords, type)
	
	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["set_cells"]["total"] += duration
	profiling_data["set_cells"]["count"] += 1
	return result

func apply_chunk(chunk_pos: Vector2i, cells_by_terrain: Dictionary):
	var start_time = Time.get_ticks_usec()
	var all_cells = []
	for terrain_index in cells_by_terrain.keys():
		var biome_name = biomes.filter(func(b): return b[0] == terrain_index)[0][1]
		print("Применение биома ", biome_name, " для ", cells_by_terrain[terrain_index].size(), " клеток")
		if cells_by_terrain[terrain_index].size() > 0:
			all_cells.append_array(cells_by_terrain[terrain_index])
			BetterTerrain.set_cells(ground_layer, cells_by_terrain[terrain_index], terrain_index)
	BetterTerrain.update_terrain_cells(ground_layer, all_cells, true)
	loaded_chunks[chunk_pos] = true
	print("Чанк ", chunk_pos, " помечен как загруженный")
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

func cache_chunk(chunk_pos: Vector2i):
	var start_time = Time.get_ticks_usec()
	var chunk_size = settings["chunk_size"]
	var start_pos = chunk_pos * chunk_size
	var cells_by_terrain = {}
	for biome in biomes:
		cells_by_terrain[biome[0]] = []

	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			var pos = start_pos + Vector2i(x, y)
			var noise_value = world_generator.noise_manager.get_cached_noise(pos)
			var selected_terrain = find_biome(noise_value)
			cells_by_terrain[selected_terrain].append(pos)

	var object_data = []
	if chunk_objects.has(chunk_pos):
		for obj in chunk_objects[chunk_pos]:
			if is_instance_valid(obj):
				var scene_path = obj.scene_file_path
				var position = obj.global_position
				var biome = obj.get_meta("biome", biomes[find_biome(world_generator.noise_manager.get_cached_noise(ground_layer.local_to_map(position)))][1])
				object_data.append({"scene_path": scene_path, "position": position, "biome": biome})
				if not object_pool.has(scene_path):
					object_pool[scene_path] = []
				if obj not in object_pool[scene_path]:
					object_pool[scene_path].append(obj)
					obj.get_parent().remove_child(obj)
					obj.set_process(false)
		chunk_objects.erase(chunk_pos)

	# Сохраняем позиции спавна из cached_chunks, если они есть
	var spawn_positions = cached_chunks.get(chunk_pos, [null, null, null, []])[CACHE_SPAWN_POSITIONS]
	cached_chunks[chunk_pos] = [cells_by_terrain, Time.get_ticks_msec() / 1000.0, object_data, spawn_positions]
	clear_chunk(chunk_pos)

	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["cache_chunk"]["total"] += duration
	profiling_data["cache_chunk"]["count"] += 1

func restore_chunk(chunk_pos: Vector2i):
	var start_time = Time.get_ticks_usec()
	var cells_by_terrain = cached_chunks[chunk_pos][CACHE_CELLS]
	var object_data = cached_chunks[chunk_pos][CACHE_OBJECTS]
	
	# Применяем клетки
	apply_chunk(chunk_pos, cells_by_terrain)
	
	# Восстанавливаем объекты
	chunk_objects[chunk_pos] = []
	for data in object_data:
		var scene_path = data["scene_path"]
		var instance = null
		if object_pool.has(scene_path) and not object_pool[scene_path].is_empty():
			instance = object_pool[scene_path].pop_front()
			print("Объект взят из пула для позиции ", data["position"])
		else:
			var scene = load(scene_path)
			if scene:
				instance = scene.instantiate()
				print("Создан новый объект для позиции ", data["position"], " (пуста пул)")

		if instance:
			instance.global_position = data["position"]
			instance.set_meta("biome", data["biome"])
			instance.set_process(true)
			world_generator.objects_node.add_child(instance)
			chunk_objects[chunk_pos].append(instance)

	# Оставляем чанк в кэше, чтобы данные не потерялись
	var duration = (Time.get_ticks_usec() - start_time) / 1000.0

func clear_chunk(chunk_pos: Vector2i):
	var start_time = Time.get_ticks_usec()
	var chunk_size = settings["chunk_size"]
	var start_pos = chunk_pos * chunk_size
	var cells_to_clear = []
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			cells_to_clear.append(start_pos + Vector2i(x, y))

	BetterTerrain.set_cells(ground_layer, cells_to_clear, TileCategory.EMPTY)

	if chunk_objects.has(chunk_pos):
		for obj in chunk_objects[chunk_pos]:
			if is_instance_valid(obj):
				var scene_path = obj.scene_file_path
				if not object_pool.has(scene_path):
					object_pool[scene_path] = []
				if obj not in object_pool[scene_path]:
					object_pool[scene_path].append(obj)
					obj.get_parent().remove_child(obj)
					obj.set_process(false)
		chunk_objects.erase(chunk_pos)

	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
	profiling_data["clear_chunk"]["total"] += duration
	profiling_data["clear_chunk"]["count"] += 1

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
	profiling_data["get_neighbor_border_positions"]["total"] += duration
	profiling_data["get_neighbor_border_positions"]["count"] += 1
	return positions

func update_border_cell(pos: Vector2i, border_cells: Dictionary):
	var start_time = Time.get_ticks_usec()
	
	var noise_value = world_generator.noise_manager.get_cached_noise(pos)
	var selected_terrain = find_biome(noise_value)
	border_cells[selected_terrain].append(pos)
	
	var duration = (Time.get_ticks_usec() - start_time) / 1000.0
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

func clean_object_pool():
	for scene_path in object_pool.keys():
		var valid_objects = []
		for obj in object_pool[scene_path]:
			if is_instance_valid(obj):
				valid_objects.append(obj)
		object_pool[scene_path] = valid_objects

func _process(delta):
	if Time.get_ticks_msec() % 30000 < delta * 1000:
		clean_object_pool()
		print_profiling_stats()
	if Input.is_action_just_pressed("ui_accept"):
		print("Загруженные чанки: ", loaded_chunks.keys())
