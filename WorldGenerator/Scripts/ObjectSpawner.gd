class_name ObjectSpawner extends Node

var world_generator: WorldGenerator
var objects_node: Node2D
var ground_layer: Node2D
var biome_settings: BiomeSettings
var chunk_objects = {}
var object_pool = {}
var boss_spawned: bool = false

const BIOME_DIFFICULTY = {
	"Sand": 0.3,
	"Grass": 0.5,
	"Forest": 0.6,
	"Winter": 0.8
}
const BASE_DIFFICULTY: float = 1.0
const DISTANCE_SCALE: float = 0.001
const MAX_DIFFICULTY: float = 5.0
const BIOME_BORDER_MARGIN: float = 1.0

func initialize(wg: WorldGenerator, on: Node2D, gl: Node2D, bs: BiomeSettings) -> void:
	world_generator = wg
	objects_node = on
	ground_layer = gl
	biome_settings = bs
	chunk_objects = world_generator.chunk_manager.chunk_objects
	print("Инициализация ObjectSpawner: ground_layer=", ground_layer, ", biome_settings=", biome_settings)
	# Отладка: выводим object_resources и structure_resources
	for resource in biome_settings.object_resources:
		print("ObjectResource: biome=", resource.biome, ", is_enemy=", resource.is_enemy, ", probability=", resource.probability, ", scenes=", resource.scenes)
	for resource in biome_settings.structure_resources:
		print("StructureResource: biome=", resource.biome, ", probability=", resource.probability, ", scenes=", resource.scenes)

func get_biome_at_position(pos: Vector2i) -> String:
	var chunk_size = world_generator.generation_settings["chunk_size"]
	var chunk_pos = Vector2i(floor(pos.x / chunk_size.x), floor(pos.y / chunk_size.y))
	
	# Проверяем cached_chunks
	if world_generator.chunk_manager.cached_chunks.has(chunk_pos):
		var cells_by_terrain = world_generator.chunk_manager.cached_chunks[chunk_pos][world_generator.chunk_manager.CACHE_CELLS]
		for terrain_index in cells_by_terrain.keys():
			if pos in cells_by_terrain[terrain_index]:
				var biome_name = biome_settings.terrain_to_biome.get(terrain_index, "")
				if biome_name == "":
					print("Ошибка: Нет биома для terrain_index ", terrain_index, " на позиции ", pos)
				else:
					print("Получен биом '", biome_name, "' для позиции ", pos, " из cached_chunks")
				return biome_name
	
	# Фаллбэк: вычисляем биом через шум
	var noise_value = world_generator.noise_manager.get_cached_noise(pos)
	var terrain_index = world_generator.chunk_manager.find_biome(noise_value)
	var biome_name = biome_settings.terrain_to_biome.get(terrain_index, "")
	if biome_name == "":
		print("Ошибка: Нет биома для terrain_index ", terrain_index, " на позиции ", pos, ", noise_value=", noise_value)
		return ""
	print("Получен биом '", biome_name, "' для позиции ", pos, " (noise_value=", noise_value, ")")
	return biome_name

func is_valid_spawn_position(pos: Vector2i) -> bool:
	var biome_name = get_biome_at_position(pos)
	if biome_name == "":
		print("Позиция ", pos, " отклонена: пустой биом")
		return false
	var check_distance = BIOME_BORDER_MARGIN
	var directions = [Vector2i(-check_distance, 0), Vector2i(check_distance, 0), Vector2i(0, -check_distance), Vector2i(0, check_distance)]

	for dir in directions:
		var check_pos = pos + dir
		var check_biome = get_biome_at_position(check_pos)
		if check_biome != biome_name:
			print("Позиция ", pos, " отклонена: соседняя позиция ", check_pos, " имеет биом '", check_biome, "' (ожидаемый: '", biome_name, "')")
			return false
	print("Позиция ", pos, " валидна для спавна в биоме '", biome_name, "'")
	return true

func get_difficulty_for_position(pos: Vector2i, biome_name: String) -> float:
	var distance = pos.length()
	var distance_difficulty = BASE_DIFFICULTY + DISTANCE_SCALE * distance
	var biome_difficulty = BIOME_DIFFICULTY.get(biome_name, 1.0)
	var final_difficulty = clamp(distance_difficulty * biome_difficulty, BASE_DIFFICULTY, MAX_DIFFICULTY)
	print("Сложность для позиции ", pos, ", биом ", biome_name, ": ", final_difficulty)
	return final_difficulty

func spawn_in_chunk(biome_name: String, positions: Array, min_pos: Vector2i, max_pos: Vector2i, chunk_pos) -> void:
	print("=== Запуск spawn_in_chunk для биома '", biome_name, "', количество позиций: ", positions.size(), ", min_pos: ", min_pos, ", max_pos: ", max_pos, " ===")
	if positions.is_empty():
		print("Ошибка: Список позиций пуст!")
		return
	spawn_objects(biome_name, positions, false, min_pos, max_pos, chunk_pos)
	spawn_objects(biome_name, positions, true, min_pos, max_pos, chunk_pos)
	spawn_structures(biome_name, positions, min_pos, max_pos, chunk_pos)
	if not boss_spawned:
		print("Попытка спавна босса")
		#boss_spawned = spawn_boss()
		print("Результат спавна босса: ", "успешно" if boss_spawned else "не удалось")

func spawn_objects(biome_name: String, possible_positions: Array, is_enemy: bool, min_pos: Vector2i, max_pos: Vector2i, chunk_pos: Vector2i) -> void:
	print("== Запуск spawn_objects: биом='", biome_name, "', тип спавна: ", "враги" if is_enemy else "объекты", ", чанк: ", chunk_pos, " ==")
	if possible_positions.is_empty():
		print("Ошибка: Нет доступных позиций для спавна в чанке ", chunk_pos)
		return

	var available_resources = []
	for resource in biome_settings.object_resources:
		if resource.biome == biome_name and resource.is_enemy == is_enemy:
			available_resources.append(resource)
	if available_resources.is_empty():
		print("Ошибка: Нет object_resources для биома='", biome_name, "', тип спавна: ", "враги" if is_enemy else "объекты")
		return
	print("Найдено ", available_resources.size(), " подходящих object_resources")

	for object_resource in available_resources:
		print("Обработка ресурса: биом='", object_resource.biome, "', тип: ", "враги" if object_resource.is_enemy else "объекты", ", вероятность=", object_resource.probability)
		
		for pos in possible_positions:
			var actual_biome = pos["biome"]
			if actual_biome != biome_name:
				print("Позиция ", pos, " отклонена: биом не совпадает (ожидаемый='", biome_name, "', актуальный='", actual_biome, "')")
				continue
			if randf() < object_resource.probability:
				print("Позиция ", pos, " выбрана для спавна")
				var instance = create_instance(object_resource, pos["position"], is_enemy, get_difficulty_for_position(pos["position"], biome_name))
				if instance:
					instance.set_meta("biome", biome_name)
					print("Успех: Создан экземпляр сцены на позиции ", pos["position"], " для биома '", biome_name, "'")
					objects_node.call_deferred("add_child", instance)
					if not chunk_objects.has(chunk_pos):
						chunk_objects[chunk_pos] = []
					chunk_objects[chunk_pos].append(instance)
				else:
					print("Ошибка: Не удалось создать экземпляр на позиции ", pos["position"])

func create_instance(object_resource: ObjectResource, pos: Vector2i, is_enemy: bool, difficulty: float) -> Node2D:
	var tile_center = ground_layer.map_to_local(pos)
	var offset = Vector2(
		randf_range(-object_resource.offset_range, object_resource.offset_range),
		randf_range(-object_resource.offset_range, object_resource.offset_range)
	)
	var final_position = tile_center + offset
	print("Создание экземпляра: позиция=", pos, ", финальная позиция=", final_position, ", min_distance=", object_resource.min_distance)

	var check_count = 0
	for existing_obj in objects_node.get_children():
		if check_count > 50:
			print("Прервано: Достигнут лимит проверки (50 объектов)")
			break
		check_count += 1
		var distance = final_position.distance_to(existing_obj.global_position)
		if distance < object_resource.min_distance:
			print("Позиция ", pos, " отклонена: слишком близко к объекту на ", existing_obj.global_position, ", расстояние=", distance, ", требуется=", object_resource.min_distance)
			return null

	var scene_path = object_resource.scenes[0].resource_path if not object_resource.scenes.is_empty() else ""
	if scene_path == "":
		print("Ошибка: Нет сцен для object_resource, биом='", object_resource.biome, "'")
		return null

	var instance = null
	if object_pool.has(scene_path) and not object_pool[scene_path].is_empty():
		instance = object_pool[scene_path].pop_front()
		instance.global_position = final_position
		print("Использован экземпляр из пула на позиции ", pos)
	else:
		var scene = object_resource.scenes[randi() % object_resource.scenes.size()]
		instance = scene.instantiate()
		if not instance:
			print("Ошибка: Не удалось инстанцировать сцену ", scene_path)
			return null
		instance.global_position = final_position
		print("Создан новый экземпляр на позиции ", pos)

	if is_enemy and instance is EnemySpawner:
		instance.biome = object_resource.biome
		instance.enemy_scenes = object_resource.scenes
		instance.max_enemies = object_resource.max_objects_per_area
		instance.spawn_radius = 500.0
		instance.respawn_time = 10.0
		instance.difficulty = difficulty
		print("Настроен EnemySpawner на позиции ", pos, ": биом='", instance.biome, "', сложность=", difficulty)

	return instance

func spawn_structures(biome_name: String, possible_positions: Array, min_pos: Vector2i, max_pos: Vector2i, chunk_pos) -> void:
	print("== Запуск spawn_structures: биом='", biome_name, "', позиций: ", possible_positions.size(), " ==")
	if possible_positions.is_empty():
		print("Ошибка: Нет доступных позиций для спавна структур")
		return

	var resources_checked = 0
	for structure_resource in biome_settings.structure_resources:
		if structure_resource.biome != biome_name:
			continue
		resources_checked += 1
		print("Обработка structure_resource: биом='", structure_resource.biome, "', вероятность=", structure_resource.probability)

		for pos in possible_positions:
			var actual_biome = pos["biome"]
			if actual_biome != biome_name:
				print("Позиция ", pos, " отклонена: биом не совпадает (ожидаемый='", biome_name, "', актуальный='", actual_biome, "')")
				continue
			# Убрана проверка find_valid_structure_position, доверяем позициям из ChunkManager
			if randf() < structure_resource.probability:
				print("Позиция ", pos, " выбрана для структуры")
				var instance = create_structure_instance(structure_resource, pos["position"])
				if instance:
					instance.set_meta("biome", biome_name)
					print("Успех: Создана структура на позиции ", pos)
					objects_node.call_deferred("add_child", instance)
					if not chunk_objects.has(chunk_pos):
						chunk_objects[chunk_pos] = []
					chunk_objects[chunk_pos].append(instance)
				else:
					print("Ошибка: Не удалось создать структуру на позиции ", pos)

	if resources_checked == 0:
		print("Ошибка: Не найдено подходящих structure_resources для биома='", biome_name, "'")

func find_valid_structure_position(structure_resource: StructureResource, pos: Vector2i) -> Vector2i:
	var structure_size = structure_resource.size
	var biome_counts = {}
	var total_tiles = structure_size.x * structure_size.y
	var threshold = 0.5  # Снижен threshold для большей гибкости
	print("Проверка позиции для структуры: позиция=", pos, ", размер=", structure_size)

	for x in range(structure_size.x):
		for y in range(structure_size.y):
			var check_pos = pos + Vector2i(x, y)
			var biome_name = get_biome_at_position(check_pos)
			if biome_name == "":
				print("Ошибка: Нет биома на позиции ", check_pos)
				return Vector2i.ZERO
			biome_counts[biome_name] = biome_counts.get(biome_name, 0) + 1

	var dominant_biome = ""
	var max_count = 0
	for biome in biome_counts.keys():
		if biome_counts[biome] > max_count:
			max_count = biome_counts[biome]
			dominant_biome = biome
	print("Доминирующий биом: '", dominant_biome, "', количество тайлов=", max_count, ", всего тайлов=", total_tiles)

	if float(max_count) / total_tiles < threshold:
		print("Позиция ", pos, " отклонена: чистота биома слишком низкая (", float(max_count) / total_tiles, " < ", threshold, ")")
		return Vector2i.ZERO

	if structure_resource.biome != dominant_biome:
		print("Позиция ", pos, " отклонена: биом структуры='", structure_resource.biome, "', доминирующий биом='", dominant_biome, "'")
		return Vector2i.ZERO

	print("Позиция ", pos, " валидна для структуры")
	return pos

func create_structure_instance(structure_resource: StructureResource, pos: Vector2i) -> Node2D:
	if structure_resource.scenes.is_empty():
		print("Ошибка: Нет сцен для structure_resource, биом='", structure_resource.biome, "'")
		return null

	var tile_center = ground_layer.map_to_local(pos)
	var scene_path = structure_resource.scenes[0].resource_path
	var instance = null

	if object_pool.has(scene_path) and not object_pool[scene_path].is_empty():
		instance = object_pool[scene_path].pop_front()
		instance.global_position = tile_center
		print("Использована структура из пула на позиции ", pos)
	else:
		var random_scene = structure_resource.scenes[randi() % structure_resource.scenes.size()]
		instance = random_scene.instantiate()
		if not instance:
			print("Ошибка: Не удалось инстанцировать сцену ", scene_path)
			return null
		instance.global_position = tile_center
		print("Создана новая структура на позиции ", pos)

	return instance

func spawn_boss() -> bool:
	if biome_settings.boss_scenes.is_empty():
		print("Ошибка: Нет сцен для босса")
		return false

	var pos = find_boss_spawn_position()
	if pos == Vector2i.ZERO:
		print("Ошибка: Не найдена позиция для спавна босса")
		return false

	var boss_scene = biome_settings.boss_scenes[randi() % biome_settings.boss_scenes.size()]
	var instance = boss_scene.instantiate()
	instance.player = PlayerManager.player
	instance.global_position = ground_layer.map_to_local(pos)
	objects_node.add_child(instance)
	print("Успех: Босс заспавнен на позиции ", pos)
	return true

func find_boss_spawn_position() -> Vector2i:
	var center = Vector2i.ZERO
	var boss_distance = 50
	var angle_step = 0.1
	var valid_positions: Array[Vector2i] = []
	var noise_scale = 0.05
	var min_noise_value = 0.1

	var unique_positions = {}
	var angle = 0.0
	while angle < TAU:
		var pos = center + Vector2i(round(boss_distance * cos(angle)), round(boss_distance * sin(angle)))
		unique_positions[pos] = true
		angle += angle_step

	for pos in unique_positions.keys():
		var boss_noise = world_generator.noise_manager.get_density_noise(pos * noise_scale)
		var actual_biome = get_biome_at_position(pos)
		if is_valid_spawn_position(pos) and boss_noise > min_noise_value and is_position_clear(pos):
			valid_positions.append(pos)
			print("Валидная позиция для босса: ", pos, ", биом='", actual_biome, "'")

	if not valid_positions.is_empty():
		valid_positions.shuffle()
		return valid_positions[0]

	print("Ошибка: Не найдено валидных позиций для босса")
	return Vector2i.ZERO

func is_position_clear(pos: Vector2i, min_distance: float = 500.0) -> bool:
	var check_pos = ground_layer.map_to_local(pos)
	for obj in objects_node.get_children():
		if obj.global_position.distance_to(check_pos) < min_distance:
			print("Позиция ", pos, " занята: объект на ", obj.global_position, ", расстояние=", obj.global_position.distance_to(check_pos))
			return false
	return true

func recycle_object(obj: Node2D) -> void:
	var scene_path = obj.scene_file_path
	if not object_pool.has(scene_path):
		object_pool[scene_path] = []
	if object_pool[scene_path].size() < 100:
		object_pool[scene_path].append(obj)
		obj.get_parent().remove_child(obj)
		print("Объект ", obj, " добавлен в пул")
	else:
		obj.queue_free()
		print("Объект ", obj, " уничтожен (пул полон)")
