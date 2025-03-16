# ObjectSpawner.gd
class_name ObjectSpawner extends Node

var world_generator: WorldGenerator
var objects_node: Node2D
var ground_layer: Node2D
var biome_settings: BiomeSettings
var chunk_objects = {}
var dominant_biome_cache = {}  # Кэш доминирующих биомов
var object_pool = {}           # Пул объектов для повторного использования

func initialize(wg: WorldGenerator, on: Node2D, gl: Node2D, bs: BiomeSettings) -> void:
	world_generator = wg
	objects_node = on
	ground_layer = gl
	biome_settings = bs
	chunk_objects = world_generator.chunk_manager.chunk_objects

# Асинхронная генерация объектов в чанке
func generate_objects(chunk_pos: Vector2i) -> void:
	var chunk_size = world_generator.generation_settings["chunk_size"]
	var start_pos = chunk_pos * chunk_size
	chunk_objects[chunk_pos] = []
	
	await process_chunk(chunk_pos, start_pos, chunk_size)

# Обработка чанка с возможностью разбивки на кадры
func process_chunk(chunk_pos: Vector2i, start_pos: Vector2i, chunk_size: Vector2i) -> void:
	var biome_info = get_dominant_biome(chunk_pos, start_pos, chunk_size)
	if not biome_info.is_single_biome:
		return
	
	var dominant_biome = biome_info.dominant_biome
	var possible_positions = biome_info.valid_positions
	
	spawn_objects(dominant_biome, possible_positions, chunk_pos, false)  # Обычные объекты
	spawn_objects(dominant_biome, possible_positions, chunk_pos, true)   # Спавнеры врагов
	spawn_structures(dominant_biome, chunk_pos)
	await get_tree().process_frame  # Даём движку время на обработку

# Универсальная функция спавна объектов
func spawn_objects(dominant_biome: String, possible_positions: Array, chunk_pos: Vector2i, is_enemy: bool) -> void:
	for object_resource in biome_settings.object_resources:
		if object_resource.biome != dominant_biome or object_resource.is_enemy != is_enemy:
			continue
		if possible_positions.is_empty():
			continue
		
		var selected_positions = []
		for pos in possible_positions:
			var noise_pos = Vector2(pos.x, pos.y) * object_resource.density_noise_scale
			var density_value = world_generator.noise_manager.get_density_noise(noise_pos)
			var adjusted_probability = object_resource.probability * density_value
			if randf() < adjusted_probability:
				selected_positions.append(pos)
		
		if selected_positions.size() > object_resource.max_objects_per_chunk:
			selected_positions.shuffle()
			selected_positions.resize(object_resource.max_objects_per_chunk)
		
		for pos in selected_positions:
			var instance = null
			if is_enemy:
				instance = create_enemy_spawner(object_resource, pos, chunk_pos)
			else:
				instance = create_object_instance(object_resource, pos, chunk_pos)
			if instance:
				objects_node.add_child(instance)
				chunk_objects[chunk_pos].append(instance)

# Создание спавнера врагов
func create_enemy_spawner(object_resource: ObjectResource, pos: Vector2i, chunk_pos: Vector2i) -> Node2D:
	var tile_center = ground_layer.map_to_local(pos)
	var offset = Vector2(
		randf_range(-object_resource.offset_range, object_resource.offset_range),
		randf_range(-object_resource.offset_range, object_resource.offset_range)
	)
	var final_position = tile_center + offset
	
	for existing_obj in chunk_objects[chunk_pos]:
		if final_position.distance_to(existing_obj.global_position) < object_resource.min_distance:
			return null
	
	var spawner = null
	var scene_path = "res://Enemies/EnemySpawner.tscn"  # Предполагаемый путь к сцене спавнера
	if object_pool.has(scene_path) and not object_pool[scene_path].is_empty():
		spawner = object_pool[scene_path].pop_back()
		spawner.global_position = final_position
	else:
		spawner = EnemySpawner.new()
		spawner.global_position = final_position
	
	spawner.biome = object_resource.biome
	spawner.enemy_scenes = object_resource.scenes
	spawner.max_enemies = object_resource.max_objects_per_chunk
	spawner.spawn_radius = 500.0
	spawner.respawn_time = 10.0
	return spawner

# Создание одиночного объекта с использованием пула
func create_object_instance(object_resource: ObjectResource, pos: Vector2i, chunk_pos: Vector2i) -> Node2D:
	if object_resource.scenes.is_empty():
		return null
	
	var tile_center = ground_layer.map_to_local(pos)
	var offset = Vector2(
		randf_range(-object_resource.offset_range, object_resource.offset_range),
		randf_range(-object_resource.offset_range, object_resource.offset_range)
	)
	var final_position = tile_center + offset
	
	for existing_obj in chunk_objects[chunk_pos]:
		if final_position.distance_to(existing_obj.global_position) < object_resource.min_distance:
			return null
	
	var scene_path = object_resource.scenes[0].resource_path  # Предполагаем одну сцену для простоты
	var instance = null
	if object_pool.has(scene_path) and not object_pool[scene_path].is_empty():
		instance = object_pool[scene_path].pop_back()
		instance.global_position = final_position
	else:
		var random_scene = object_resource.scenes[randi() % object_resource.scenes.size()]
		instance = random_scene.instantiate()
		instance.global_position = final_position
	return instance

# Кэшированное определение доминирующего биома и валидных позиций
func get_dominant_biome(chunk_pos: Vector2i, start_pos: Vector2i, chunk_size: Vector2i) -> Dictionary:
	if dominant_biome_cache.has(chunk_pos):
		return dominant_biome_cache[chunk_pos]
	
	var biome_counts = {}
	var total_cells = 0
	var valid_positions = []
	
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			var pos = start_pos + Vector2i(x, y)
			var tile_data = ground_layer.get_cell_tile_data(pos)
			if tile_data:
				var terrain_index = tile_data.terrain
				if biome_settings.terrain_to_biome.has(terrain_index):
					var biome_name = biome_settings.terrain_to_biome[terrain_index]
					biome_counts[biome_name] = (biome_counts.get(biome_name, 0) + 1)
					total_cells += 1
					valid_positions.append(pos)  # Все валидные позиции для спавна
	
	var dominant_biome = null
	var is_single_biome = false
	
	if biome_counts.size() == 1:
		dominant_biome = biome_counts.keys()[0]
		is_single_biome = true
	else:
		var max_count = 0
		for biome_name in biome_counts:
			if biome_counts[biome_name] > max_count:
				max_count = biome_counts[biome_name]
				dominant_biome = biome_name
		if max_count >= total_cells * 0.9:
			is_single_biome = true
	
	var result = {
		"dominant_biome": dominant_biome,
		"is_single_biome": is_single_biome,
		"valid_positions": valid_positions
	}
	dominant_biome_cache[chunk_pos] = result
	return result

# Спавн структур
func spawn_structures(dominant_biome: String, chunk_pos: Vector2i) -> void:
	var chunk_size = world_generator.generation_settings["chunk_size"]
	var start_pos = chunk_pos * chunk_size
	
	for structure_resource in biome_settings.structure_resources:
		if structure_resource.biome != dominant_biome:
			continue
		if randf() < structure_resource.probability:
			var valid_position = find_valid_structure_position(structure_resource, chunk_pos, chunk_size, start_pos, dominant_biome)
			if valid_position != Vector2i.ZERO:
				var instances = create_structure_instances(structure_resource, valid_position, chunk_pos)
				for instance in instances:
					objects_node.add_child(instance)
					chunk_objects[chunk_pos].append(instance)

# Создание экземпляров структуры с разборкой на отдельные объекты
func create_structure_instances(structure_resource: StructureResource, pos: Vector2i, chunk_pos: Vector2i) -> Array:
	if structure_resource.scenes.is_empty():
		return []
	
	var tile_center = ground_layer.map_to_local(pos)
	var structure_instance = structure_resource.scenes[randi() % structure_resource.scenes.size()].instantiate()
	var instances = []
	
	for child in structure_instance.get_children():
		if child is Node2D:
			child.global_position = tile_center + child.position
			instances.append(child)
			structure_instance.remove_child(child)
	
	structure_instance.queue_free()
	return instances

# Поиск подходящей позиции для структуры
func find_valid_structure_position(structure_resource: StructureResource, chunk_pos: Vector2i, chunk_size: Vector2i, start_pos: Vector2i, dominant_biome: String) -> Vector2i:
	var attempts = 10
	var structure_size = structure_resource.size
	
	var max_x = chunk_size.x - structure_size.x + 1
	var max_y = chunk_size.y - structure_size.y + 1
	
	if max_x <= 0 or max_y <= 0:
		return Vector2i.ZERO
	
	for _i in range(attempts):
		var random_pos = start_pos + Vector2i(randi() % max_x, randi() % max_y)
		if is_structure_position_valid(random_pos, structure_size, dominant_biome):
			return random_pos
	
	return Vector2i.ZERO

# Проверка валидности позиции для структуры
func is_structure_position_valid(pos: Vector2i, structure_size: Vector2i, dominant_biome: String) -> bool:
	for x in range(structure_size.x):
		for y in range(structure_size.y):
			var check_pos = pos + Vector2i(x, y)
			var tile_data = ground_layer.get_cell_tile_data(check_pos)
			if not tile_data:
				return false
			var terrain_index = tile_data.terrain
			if not biome_settings.terrain_to_biome.has(terrain_index):
				return false
			var biome_name = biome_settings.terrain_to_biome[terrain_index]
			if biome_name != dominant_biome:
				return false
	return true

# Переработка объекта в пул
func recycle_object(obj: Node2D) -> void:
	var scene_path = obj.scene_file_path
	if not object_pool.has(scene_path):
		object_pool[scene_path] = []
	object_pool[scene_path].append(obj)
	obj.get_parent().remove_child(obj)
