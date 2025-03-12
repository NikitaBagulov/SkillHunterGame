class_name WorldGenerator extends Node2D

@onready var ground_layer = $GroundedLayer

var tile_set

var noise = FastNoiseLite.new()
var density_noise = FastNoiseLite.new()

@export var generation_settings = {
	"chunk_size": Vector2i(8, 8),
	"render_distance": 4,
	"tile_scale": 1.0,
	"noise_type": FastNoiseLite.TYPE_PERLIN,
	"noise_frequency": 0.005,
	"noise_octaves": 3,
	"noise_seed": 0,
	"noise_offset": Vector2(0, 0),
	"chunk_cache_time": 120.0,
	"chunk_load_interval": 0.01,
	"density_noise_frequency": 0.05
}

# Список биомов: [terrain_index, name, min_threshold, max_threshold, weight]
@export var biomes = [
	[0, "Water", -1.0, -0.5, 1.0],
	[1, "Grass", -0.5, 0.0, 1.0],
	[0, "Water", 0.0, 0.2, 1.0],
	[3, "Forest", 0.2, 0.6, 1.0],
	[0, "Water", 0.6, 0.7, 1.0],
	[2, "Winter", 0.7, 1.0, 1.0]
]

# Ресурсы для объектов и структур
@export var object_resources: Array[ObjectResource]
@export var structure_resources: Array[StructureResource]

# Хранение чанков, объектов и кэш
var loaded_chunks = {}
var cached_chunks = {}
var noise_cache = {}
var player = null
var last_player_chunk = Vector2i.ZERO
var chunk_queue = []
var objects_node: Node2D
var chunk_objects = {}
var terrain_to_biome = {}

# Структура для сохранения данных об объектах
class ObjectData:
	var scene_path: String
	var position: Vector2

	func _init(s_path: String, pos: Vector2):
		scene_path = s_path
		position = pos

func _ready():
	tile_set = ground_layer.tile_set
	# Инициализация основного шума
	noise.noise_type = generation_settings["noise_type"]
	noise.seed = generation_settings["noise_seed"] if generation_settings["noise_seed"] != 0 else randi()
	noise.frequency = generation_settings["noise_frequency"]
	noise.fractal_octaves = generation_settings["noise_octaves"]
	
	# Инициализация шума для плотности
	density_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	density_noise.seed = noise.seed + 1
	density_noise.frequency = generation_settings["density_noise_frequency"]
	density_noise.fractal_octaves = 3
	
	#player = PlayerManager.get_player()
	#if not player:
		#print("Ошибка: Игрок не найден!")
		#return
	
	objects_node = Node2D.new()
	objects_node.name = "ObjectsNode"
	add_child(objects_node)
	
	for biome in biomes:
		if not terrain_to_biome.has(biome[0]):
			terrain_to_biome[biome[0]] = biome[1]
	
	var update_timer = Timer.new()
	update_timer.wait_time = 0.5
	update_timer.connect("timeout", Callable(self, "check_player_position"))
	add_child(update_timer)
	update_timer.start()
	
	var load_timer = Timer.new()
	load_timer.wait_time = generation_settings["chunk_load_interval"]
	load_timer.connect("timeout", Callable(self, "load_next_chunk"))
	add_child(load_timer)
	load_timer.start()
	
	# Спавним игрока после первой генерации
	await load_next_chunk()
	spawn_player()

func spawn_player():
	if player:
		print("Игрок уже спавнен!")
		return
	
	# Ищем безопасную позицию (не на воде)
	var safe_position = find_safe_spawn_position()
	if safe_position:
		# Создаём игрока через PlayerManager
		PlayerManager.add_player_instance(self)  # Передаём WorldGenerator как родителя
		player = PlayerManager.get_player()
		PlayerManager.set_player_position(safe_position)
		# Player уже добавлен как дочерний элемент через add_player_instance
		PlayerManager.set_player(player)
		print("Игрок спавнен в: ", safe_position)
	else:
		print("Не удалось найти безопасную позицию для спавна!")

func find_safe_spawn_position() -> Vector2:
	var attempts = 100
	var chunk_size = generation_settings["chunk_size"]
	var player_chunk = last_player_chunk
	
	for _i in range(attempts):
		var x = player_chunk.x * chunk_size.x + randi() % chunk_size.x
		var y = player_chunk.y * chunk_size.y + randi() % chunk_size.y
		var pos = Vector2i(x, y)
		var noise_value = get_cached_noise(pos)
		var terrain_index = -1
		
		for biome in biomes:
			if noise_value >= biome[2] and noise_value <= biome[3]:
				terrain_index = biome[0]
				break
		
		if terrain_index != 0:
			var world_pos = ground_layer.map_to_local(pos)
			return world_pos
	
	print("Предупреждение: Не найдено безопасное место для спавна после ", attempts, " попыток!")
	return Vector2.ZERO

func check_player_position():
	if not player:
		return
	
	var player_pos = player.global_position / (tile_set.tile_size * generation_settings["tile_scale"])
	var player_chunk = Vector2i(
		floor(player_pos.x / generation_settings["chunk_size"].x),
		floor(player_pos.y / generation_settings["chunk_size"].y)
	)
	
	if player_chunk == last_player_chunk:
		return
	last_player_chunk = player_chunk
	
	var new_chunks = {}
	for x in range(player_chunk.x - generation_settings["render_distance"], player_chunk.x + generation_settings["render_distance"] + 1):
		for y in range(player_chunk.y - generation_settings["render_distance"], player_chunk.y + generation_settings["render_distance"] + 1):
			var chunk_pos = Vector2i(x, y)
			new_chunks[chunk_pos] = true
			if not loaded_chunks.has(chunk_pos) and not chunk_queue.has(chunk_pos):
				if cached_chunks.has(chunk_pos):
					restore_chunk(chunk_pos)
				else:
					chunk_queue.append(chunk_pos)
	
	var current_time = Time.get_ticks_msec() / 1000.0
	for chunk_pos in loaded_chunks.keys():
		if not new_chunks.has(chunk_pos):
			cache_chunk(chunk_pos)
	
	var to_remove = []
	for chunk_pos in cached_chunks.keys():
		var timestamp = cached_chunks[chunk_pos][1]
		if current_time - timestamp > generation_settings["chunk_cache_time"]:
			to_remove.append(chunk_pos)
	for chunk_pos in to_remove:
		clear_chunk(chunk_pos)
		cached_chunks.erase(chunk_pos)
	
	loaded_chunks = new_chunks
	
	# Обновляем границы после изменения чанков
	if ground_layer is LevelTileMap:
		ground_layer.update_bounds()

func get_current_bounds() -> Array[Vector2]:
	if loaded_chunks.is_empty():
		return [Vector2.ZERO, Vector2.ZERO]
	
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	for chunk_pos in loaded_chunks.keys():
		var chunk_start = chunk_pos * generation_settings["chunk_size"]
		var chunk_end = chunk_start + generation_settings["chunk_size"]
		
		min_x = min(min_x, chunk_start.x)
		min_y = min(min_y, chunk_start.y)
		max_x = max(max_x, chunk_end.x)
		max_y = max(max_y, chunk_end.y)
	
	# Учитываем tile_scale для мировых координат
	var tile_size = tile_set.tile_size * generation_settings["tile_scale"]
	return [
		Vector2(min_x * tile_size.x, min_y * tile_size.y),
		Vector2(max_x * tile_size.x, max_y * tile_size.y)
	]

func load_next_chunk():
	if chunk_queue.is_empty():
		return
	
	var chunk_pos = chunk_queue.pop_front()
	generate_chunk(chunk_pos)

func generate_chunk(chunk_pos: Vector2i):
	var start_pos = chunk_pos * generation_settings["chunk_size"]
	var cells_by_terrain = {}
	
	for biome in biomes:
		cells_by_terrain[biome[0]] = []
	
	for x in range(generation_settings["chunk_size"].x):
		for y in range(generation_settings["chunk_size"].y):
			var pos = start_pos + Vector2i(x, y)
			var noise_value = get_cached_noise(pos)
			
			var selected_terrain = -1
			for biome in biomes:
				if noise_value >= biome[2] and noise_value <= biome[3]:
					selected_terrain = biome[0]
					break
			if selected_terrain != -1:
				cells_by_terrain[selected_terrain].append(pos)
	
	apply_chunk(chunk_pos, cells_by_terrain)
	generate_objects(chunk_pos)

func generate_objects(chunk_pos: Vector2i):
	var start_pos = chunk_pos * generation_settings["chunk_size"]
	chunk_objects[chunk_pos] = []
	
	# Собираем все подходящие тайлы для биома
	var possible_positions = {}
	for biome in biomes:
		possible_positions[biome[1]] = []
	
	for x in range(generation_settings["chunk_size"].x):
		for y in range(generation_settings["chunk_size"].y):
			var pos = start_pos + Vector2i(x, y)
			var tile_data = ground_layer.get_cell_tile_data(pos)
			if tile_data:
				var terrain_index = tile_data.terrain
				var biome_name = terrain_to_biome[terrain_index]
				possible_positions[biome_name].append(pos)
	
	# Генерация одиночных объектов
	for object_resource in object_resources:
		if not possible_positions.has(object_resource.biome):
			continue
		
		var positions = possible_positions[object_resource.biome]
		if positions.is_empty():
			continue
		
		# Выбираем тайлы для размещения объектов
		var selected_positions = []
		for pos in positions:
			var noise_pos = Vector2(pos.x, pos.y) * object_resource.density_noise_scale
			var density_value = (density_noise.get_noise_2d(noise_pos.x, noise_pos.y) + 1.0) / 2.0
			var adjusted_probability = object_resource.probability * density_value
			
			if randf() < adjusted_probability:
				selected_positions.append(pos)
		
		# Ограничиваем количество объектов
		if selected_positions.size() > object_resource.max_objects_per_chunk:
			selected_positions.shuffle()
			selected_positions.resize(object_resource.max_objects_per_chunk)
		
		# Размещаем объекты
		for pos in selected_positions:
			var tile_center = ground_layer.map_to_local(pos)
			var offset = Vector2(
				randf_range(-object_resource.offset_range, object_resource.offset_range),
				randf_range(-object_resource.offset_range, object_resource.offset_range)
			)
			var final_position = tile_center + offset
			
			# Проверяем, нет ли поблизости других объектов
			var too_close = false
			for existing_obj in chunk_objects[chunk_pos]:
				var dist = final_position.distance_to(existing_obj.global_position)
				if dist < object_resource.min_distance:
					too_close = true
					break
			
			if not too_close:
				# Выбираем случайную сцену из списка
				if object_resource.scenes.is_empty():
					continue
				var random_scene = object_resource.scenes[randi() % object_resource.scenes.size()]
				var instance = random_scene.instantiate()
				instance.global_position = final_position
				objects_node.add_child(instance)
				chunk_objects[chunk_pos].append(instance)
	
	# Генерация структур
	for structure_resource in structure_resources:
		if randf() < structure_resource.probability:
			for attempt in range(10):
				var x = randi() % (generation_settings["chunk_size"].x - structure_resource.size.x + 1)
				var y = randi() % (generation_settings["chunk_size"].y - structure_resource.size.y + 1)
				var top_left = start_pos + Vector2i(x, y)
				var tile_data = ground_layer.get_cell_tile_data(top_left)
				if tile_data:
					var terrain_index = tile_data.terrain
					var biome_name = terrain_to_biome[terrain_index]
					if biome_name == structure_resource.biome:
						var fits = true
						for dx in range(structure_resource.size.x):
							for dy in range(structure_resource.size.y):
								var check_pos = top_left + Vector2i(dx, dy)
								var check_tile_data = ground_layer.get_cell_tile_data(check_pos)
								if not check_tile_data or check_tile_data.terrain != terrain_index:
									fits = false
									break
							if not fits:
								break
						if fits:
							var instance = structure_resource.scene.instantiate()
							instance.global_position = ground_layer.map_to_local(top_left)
							objects_node.add_child(instance)
							chunk_objects[chunk_pos].append(instance)
							break

func cache_chunk(chunk_pos: Vector2i):
	var cells_by_terrain = {}
	for biome in biomes:
		cells_by_terrain[biome[0]] = []
	
	var start_pos = chunk_pos * generation_settings["chunk_size"]
	for x in range(generation_settings["chunk_size"].x):
		for y in range(generation_settings["chunk_size"].y):
			var pos = start_pos + Vector2i(x, y)
			var tile_data = ground_layer.get_cell_tile_data(pos)
			if tile_data:
				var terrain_index = tile_data.terrain
				cells_by_terrain[terrain_index].append(pos)
	
	# Сохраняем данные об объектах
	var object_data = []
	if chunk_objects.has(chunk_pos):
		for obj in chunk_objects[chunk_pos]:
			var data = ObjectData.new(obj.scene_file_path, obj.global_position)
			object_data.append(data)
	
	cached_chunks[chunk_pos] = [cells_by_terrain, Time.get_ticks_msec() / 1000.0, object_data]
	clear_chunk(chunk_pos)

func restore_chunk(chunk_pos: Vector2i):
	var cells_by_terrain = cached_chunks[chunk_pos][0]
	var object_data = cached_chunks[chunk_pos][2]
	apply_chunk(chunk_pos, cells_by_terrain)
	cached_chunks.erase(chunk_pos)
	
	# Восстанавливаем объекты
	chunk_objects[chunk_pos] = []
	for data in object_data:
		var scene = load(data.scene_path)
		if scene:
			var instance = scene.instantiate()
			instance.global_position = data.position
			objects_node.add_child(instance)
			chunk_objects[chunk_pos].append(instance)

func apply_chunk(chunk_pos: Vector2i, cells_by_terrain: Dictionary):
	for terrain_index in cells_by_terrain.keys():
		if cells_by_terrain[terrain_index].size() > 0:
			ground_layer.set_cells_terrain_connect(cells_by_terrain[terrain_index], 0, terrain_index, false)
	update_chunk_borders(chunk_pos)

func clear_chunk(chunk_pos: Vector2i):
	var start_pos = chunk_pos * generation_settings["chunk_size"]
	for x in range(generation_settings["chunk_size"].x):
		for y in range(generation_settings["chunk_size"].y):
			var pos = start_pos + Vector2i(x, y)
			ground_layer.erase_cell(pos)
	
	if chunk_objects.has(chunk_pos):
		for obj in chunk_objects[chunk_pos]:
			obj.queue_free()
		chunk_objects.erase(chunk_pos)

func update_chunk_borders(chunk_pos: Vector2i):
	var start_pos = chunk_pos * generation_settings["chunk_size"]
	var chunk_size = generation_settings["chunk_size"]
	var border_cells = {}
	
	for biome in biomes:
		border_cells[biome[0]] = []
	
	var neighbors = [
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(0, -1), Vector2i(0, 1)
	]
	
	for x in range(chunk_size.x):
		for y in [0, chunk_size.y - 1]:
			var pos = start_pos + Vector2i(x, y)
			update_border_cell(pos, border_cells)
	for y in range(chunk_size.y):
		for x in [0, chunk_size.x - 1]:
			var pos = start_pos + Vector2i(x, y)
			update_border_cell(pos, border_cells)
	
	for neighbor in neighbors:
		var neighbor_chunk = chunk_pos + neighbor
		if loaded_chunks.has(neighbor_chunk):
			var neighbor_start = neighbor_chunk * chunk_size
			if neighbor.x == -1:
				for y in range(chunk_size.y):
					var pos = neighbor_start + Vector2i(chunk_size.x - 1, y)
					update_border_cell(pos, border_cells)
			elif neighbor.x == 1:
				for y in range(chunk_size.y):
					var pos = neighbor_start + Vector2i(0, y)
					update_border_cell(pos, border_cells)
			elif neighbor.y == -1:
				for x in range(chunk_size.x):
					var pos = neighbor_start + Vector2i(x, chunk_size.y - 1)
					update_border_cell(pos, border_cells)
			elif neighbor.y == 1:
				for x in range(chunk_size.x):
					var pos = neighbor_start + Vector2i(x, 0)
					update_border_cell(pos, border_cells)
	
	for terrain_index in border_cells.keys():
		if border_cells[terrain_index].size() > 0:
			ground_layer.set_cells_terrain_connect(border_cells[terrain_index], 0, terrain_index, false)
			ground_layer.set_cells_terrain_connect(border_cells[terrain_index], 0, terrain_index, false)

func update_border_cell(pos: Vector2i, border_cells: Dictionary):
	var noise_value = get_cached_noise(pos)
	var selected_terrain = 0
	for biome in biomes:
		if noise_value >= biome[2] and noise_value <= biome[3]:
			selected_terrain = biome[0]
			break
	border_cells[selected_terrain].append(pos)

func get_cached_noise(pos: Vector2i) -> float:
	if noise_cache.has(pos):
		return noise_cache[pos]
	var noise_pos = Vector2(pos.x, pos.y) * generation_settings["tile_scale"] + generation_settings["noise_offset"]
	var value = noise.get_noise_2d(noise_pos.x, noise_pos.y)
	noise_cache[pos] = value
	return value

func _get_biome_name(terrain_index: int) -> String:
	for biome in biomes:
		if biome[0] == terrain_index:
			return biome[1]
	return "Unknown"

func _process(_delta):
	if not player:
		return
	
	var player_pos = player.global_position / (tile_set.tile_size * generation_settings["tile_scale"])
	var player_tile_pos = Vector2i(floor(player_pos.x), floor(player_pos.y))
	var noise_value = get_cached_noise(player_tile_pos)
	#
	#var fps = Engine.get_frames_per_second()
	#var memory_usage = OS.get_static_memory_usage() / 1024.0 / 1024.0
	#var chunk_count = loaded_chunks.size() + cached_chunks.size()
	#var queue_size = chunk_queue.size()
	#print("FPS: ", fps, " | Memory: ", memory_usage, " MB | Chunks: ", chunk_count, " | Queue: ", queue_size)
