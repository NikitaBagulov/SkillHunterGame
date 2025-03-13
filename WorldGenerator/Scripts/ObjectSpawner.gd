class_name ObjectSpawner extends Node

var world_generator: WorldGenerator
var objects_node: Node2D
var ground_layer: Node2D
var biome_settings: BiomeSettings
var chunk_objects = {}

func initialize(wg: WorldGenerator, on: Node2D, gl: Node2D, bs: BiomeSettings):
	world_generator = wg
	objects_node = on
	ground_layer = gl
	biome_settings = bs
	chunk_objects = world_generator.chunk_manager.chunk_objects

func generate_objects(chunk_pos: Vector2i):
	var chunk_size = world_generator.generation_settings["chunk_size"]
	var start_pos = chunk_pos * chunk_size
	chunk_objects[chunk_pos] = []
	
	# Определяем доминирующий биом в чанке
	var biome_info = get_dominant_biome(chunk_pos, start_pos, chunk_size)
	if not biome_info.is_single_biome:
		return  # Пропускаем спавн, если чанк не "чистый"
	
	var dominant_biome = biome_info.dominant_biome
	var possible_positions = get_possible_positions(chunk_pos, start_pos, chunk_size, dominant_biome)
	
	# Спавним объекты и структуры для доминирующего биома
	spawn_single_objects(dominant_biome, possible_positions, chunk_pos)
	spawn_structures(dominant_biome, chunk_pos)

# Подсчет биомов в чанке и определение доминирующего
func get_dominant_biome(chunk_pos: Vector2i, start_pos: Vector2i, chunk_size: Vector2i) -> Dictionary:
	var biome_counts = {}
	var total_cells = 0
	
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
		if max_count >= total_cells * 0.9:  # Порог 90%
			is_single_biome = true
	
	return {"dominant_biome": dominant_biome, "is_single_biome": is_single_biome}

# Получение возможных позиций для спавна в чанке
func get_possible_positions(chunk_pos: Vector2i, start_pos: Vector2i, chunk_size: Vector2i, dominant_biome: String) -> Array:
	var positions = []
	
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			var pos = start_pos + Vector2i(x, y)
			var tile_data = ground_layer.get_cell_tile_data(pos)
			if tile_data:
				var terrain_index = tile_data.terrain
				if biome_settings.terrain_to_biome.has(terrain_index):
					var biome_name = biome_settings.terrain_to_biome[terrain_index]
					if biome_name == dominant_biome:
						positions.append(pos)
	
	return positions

# Спавн одиночных объектов
func spawn_single_objects(dominant_biome: String, possible_positions: Array, chunk_pos: Vector2i):
	for object_resource in biome_settings.object_resources:
		if object_resource.biome != dominant_biome:
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
			var instance = create_object_instance(object_resource, pos, chunk_pos)  # Передаем chunk_pos
			if instance:
				objects_node.add_child(instance)
				chunk_objects[chunk_pos].append(instance)

# Спавн структур
# Спавн структур с разборкой на отдельные объекты
func spawn_structures(dominant_biome: String, chunk_pos: Vector2i):
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
	
	# Извлекаем дочерние узлы структуры
	for child in structure_instance.get_children():
		if child is Node2D:  # Убеждаемся, что это 2D-объект
			child.global_position = tile_center + child.position  # Смещаем относительно базовой позиции
			instances.append(child)
			structure_instance.remove_child(child)  # Удаляем из структуры, чтобы добавить в objects_node
	
	# Удаляем временный экземпляр структуры
	structure_instance.queue_free()
	return instances

# Поиск подходящей позиции для структуры
func find_valid_structure_position(structure_resource: StructureResource, chunk_pos: Vector2i, chunk_size: Vector2i, start_pos: Vector2i, dominant_biome: String) -> Vector2i:
	var attempts = 10  # Количество попыток найти позицию
	var structure_size = structure_resource.size
	
	# Ограничиваем диапазон случайных позиций, чтобы структура не выходила за пределы чанка
	var max_x = chunk_size.x - structure_size.x + 1
	var max_y = chunk_size.y - structure_size.y + 1
	
	if max_x <= 0 or max_y <= 0:
		return Vector2i.ZERO  # Структура слишком большая для чанка
	
	for _i in range(attempts):
		var random_pos = start_pos + Vector2i(randi() % max_x, randi() % max_y)
		if is_structure_position_valid(random_pos, structure_size, dominant_biome):
			return random_pos
	
	return Vector2i.ZERO  # Не нашли подходящую позицию

# Проверка, что позиция подходит для структуры
func is_structure_position_valid(pos: Vector2i, structure_size: Vector2i, dominant_biome: String) -> bool:
	for x in range(structure_size.x):
		for y in range(structure_size.y):
			var check_pos = pos + Vector2i(x, y)
			var tile_data = ground_layer.get_cell_tile_data(check_pos)
			if not tile_data:
				return false  # Пустая клетка
			var terrain_index = tile_data.terrain
			if not biome_settings.terrain_to_biome.has(terrain_index):
				return false
			var biome_name = biome_settings.terrain_to_biome[terrain_index]
			if biome_name != dominant_biome:
				return false  # Не тот биом
	return true

# Вспомогательная функция для создания экземпляра структуры
func create_structure_instance(structure_resource: StructureResource, pos: Vector2i) -> Node2D:
	if structure_resource.scenes.is_empty():
		return null
	
	var tile_center = ground_layer.map_to_local(pos)
	var instance = structure_resource.scenes[randi() % structure_resource.scenes.size()].instantiate()
	instance.global_position = tile_center  # Позиция — левый верхний угол структуры
	return instance

# Вспомогательная функция для создания экземпляра объекта
func create_object_instance(object_resource: ObjectResource, pos: Vector2i, chunk_pos: Vector2i) -> Node2D:
	if object_resource.scenes.is_empty():
		return null
	
	var tile_center = ground_layer.map_to_local(pos)
	var offset = Vector2(randf_range(-object_resource.offset_range, object_resource.offset_range),
						randf_range(-object_resource.offset_range, object_resource.offset_range))
	var final_position = tile_center + offset
	
	for existing_obj in chunk_objects[chunk_pos]:  # Теперь chunk_pos доступен
		if final_position.distance_to(existing_obj.global_position) < object_resource.min_distance:
			return null
	
	var random_scene = object_resource.scenes[randi() % object_resource.scenes.size()]
	var instance = random_scene.instantiate()
	instance.global_position = final_position
	return instance
