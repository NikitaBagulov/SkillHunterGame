class_name ObjectSpawner extends Node

var world_generator: WorldGenerator
var objects_node: Node2D
var ground_layer: Node2D
var biome_settings: BiomeSettings
var chunk_objects = {}
var object_pool = {}

var biome_border_margin: float = 2.0
var area_size: float = 100.0
var boss_spawned: bool = false

func initialize(wg: WorldGenerator, on: Node2D, gl: Node2D, bs: BiomeSettings) -> void:
	world_generator = wg
	objects_node = on
	ground_layer = gl
	biome_settings = bs
	chunk_objects = world_generator.chunk_manager.chunk_objects

func generate_objects_in_area(min_pos: Vector2i, max_pos: Vector2i, is_enemy: bool = false) -> void:
	var step = 2
	var positions_by_biome = {}
	
	for x in range(min_pos.x, max_pos.x + 1, step):
		for y in range(min_pos.y, max_pos.y + 1, step):
			var pos = Vector2i(x, y)
			if is_valid_spawn_position(pos):
				var noise_value = world_generator.noise_manager.get_cached_noise(pos)
				var terrain_index = world_generator.chunk_manager.find_biome(noise_value)
				var biome_name = biome_settings.terrain_to_biome.get(terrain_index, "")
				if biome_name == "water" or biome_name == "":
					continue
				if not positions_by_biome.has(biome_name):
					positions_by_biome[biome_name] = []
				positions_by_biome[biome_name].append(pos)
	
	for biome_name in positions_by_biome.keys():
		spawn_objects(biome_name, positions_by_biome[biome_name], is_enemy, min_pos, max_pos)
	
	if not is_enemy:
		spawn_structures_in_area(min_pos, max_pos)
	
	if not boss_spawned and not is_enemy:
		boss_spawned = spawn_boss()

func is_valid_spawn_position(pos: Vector2i) -> bool:
	var noise_value = world_generator.noise_manager.get_cached_noise(pos)
	var terrain_index = world_generator.chunk_manager.find_biome(noise_value)
	var biome_name = biome_settings.terrain_to_biome.get(terrain_index, "")
	if biome_name == "water":
		return false
	return is_away_from_biome_border(pos, terrain_index)

func is_away_from_biome_border(pos: Vector2i, terrain_index: int) -> bool:
	var check_distance = biome_border_margin
	var directions = [
		Vector2i(-check_distance, 0), Vector2i(check_distance, 0),
		Vector2i(0, -check_distance), Vector2i(0, check_distance)
	]
	
	for dir in directions:
		var check_pos = pos + dir
		var noise_value = world_generator.noise_manager.get_cached_noise(check_pos)
		var check_terrain = world_generator.chunk_manager.find_biome(noise_value)
		if check_terrain != terrain_index:
			return false
	return true

func spawn_objects(dominant_biome: String, possible_positions: Array, is_enemy: bool, min_pos: Vector2i, max_pos: Vector2i) -> void:
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
		
		var area_width = max_pos.x - min_pos.x + 1
		var area_height = max_pos.y - min_pos.y + 1
		var area_pixels = area_width * area_height * world_generator.tile_set.tile_size.x * world_generator.generation_settings["tile_scale"]
		var area_units = area_pixels / (area_size * area_size)
		var max_objects = int(object_resource.max_objects_per_area * area_units)
		
		if selected_positions.size() > max_objects:
			selected_positions.shuffle()
			selected_positions.resize(max_objects)
		
		for pos in selected_positions:
			var instance = null
			if is_enemy:
				instance = create_enemy_spawner(object_resource, pos)
			else:
				instance = create_object_instance(object_resource, pos)
			if instance:
				call_deferred("add_instance_to_node", instance)

func add_instance_to_node(instance: Node2D) -> void:
	objects_node.add_child(instance)

func create_enemy_spawner(object_resource: ObjectResource, pos: Vector2i) -> Node2D:
	var tile_center = ground_layer.map_to_local(pos)
	var offset = Vector2(
		randf_range(-object_resource.offset_range, object_resource.offset_range),
		randf_range(-object_resource.offset_range, object_resource.offset_range)
	)
	var final_position = tile_center + offset
	
	for existing_obj in objects_node.get_children():
		if final_position.distance_to(existing_obj.global_position) < object_resource.min_distance:
			return null
	
	var spawner = null
	var scene_path = "res://Enemies/EnemySpawner.tscn"
	if object_pool.has(scene_path) and not object_pool[scene_path].is_empty():
		spawner = object_pool[scene_path].pop_back()
		spawner.global_position = final_position
	else:
		spawner = EnemySpawner.new()
		spawner.global_position = final_position
	
	spawner.biome = object_resource.biome
	spawner.enemy_scenes = object_resource.scenes
	spawner.max_enemies = object_resource.max_objects_per_area
	spawner.spawn_radius = 500.0
	spawner.respawn_time = 10.0
	return spawner

func create_object_instance(object_resource: ObjectResource, pos: Vector2i) -> Node2D:
	if object_resource.scenes.is_empty():
		return null
	
	var tile_center = ground_layer.map_to_local(pos)
	var offset = Vector2(
		randf_range(-object_resource.offset_range, object_resource.offset_range),
		randf_range(-object_resource.offset_range, object_resource.offset_range)
	)
	var final_position = tile_center + offset
	
	for existing_obj in objects_node.get_children():
		if final_position.distance_to(existing_obj.global_position) < object_resource.min_distance:
			return null
	
	var scene_path = object_resource.scenes[0].resource_path
	var instance = null
	if object_pool.has(scene_path) and not object_pool[scene_path].is_empty():
		instance = object_pool[scene_path].pop_back()
		instance.global_position = final_position
	else:
		var random_scene = object_resource.scenes[randi() % object_resource.scenes.size()]
		instance = random_scene.instantiate()
		instance.global_position = final_position
	return instance

func spawn_structures_in_area(min_pos: Vector2i, max_pos: Vector2i) -> void:
	var step = 4
	for x in range(min_pos.x, max_pos.x + 1, step):
		for y in range(min_pos.y, max_pos.y + 1, step):
			var pos = Vector2i(x, y)
			var noise_value = world_generator.noise_manager.get_cached_noise(pos)
			var terrain_index = world_generator.chunk_manager.find_biome(noise_value)
			var biome_name = biome_settings.terrain_to_biome.get(terrain_index, "")
			if biome_name == "water" or not is_away_from_biome_border(pos, terrain_index):
				continue
			
			for structure_resource in biome_settings.structure_resources:
				if structure_resource.biome != biome_name:
					continue
				if randf() < structure_resource.probability:
					var valid_position = find_valid_structure_position(structure_resource, pos, biome_name)
					if valid_position != Vector2i.ZERO:
						var instance = create_structure_instance(structure_resource, valid_position)

						call_deferred("add_instance_to_node", instance)

func find_valid_structure_position(structure_resource: StructureResource, pos: Vector2i, dominant_biome: String) -> Vector2i:
	var structure_size = structure_resource.size
	if is_structure_position_valid(pos, structure_size, dominant_biome):
		return pos
	return Vector2i.ZERO

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

func create_structure_instance(structure_resource: StructureResource, pos: Vector2i) -> Node2D:
	if structure_resource.scenes.is_empty():
		return null
	
	var tile_center = ground_layer.map_to_local(pos)
	var structure_instance = structure_resource.scenes[randi() % structure_resource.scenes.size()].instantiate()

	return structure_instance

func recycle_object(obj: Node2D) -> void:
	var scene_path = obj.scene_file_path
	if not object_pool.has(scene_path):
		object_pool[scene_path] = []
	if object_pool[scene_path].size() < 100:
		object_pool[scene_path].append(obj)
		obj.get_parent().remove_child(obj)
	else:
		obj.queue_free()

func spawn_boss() -> bool:
	if biome_settings.boss_scenes.is_empty():
		return false
	
	var pos = find_boss_spawn_position()
	if pos == Vector2i.ZERO:
		return false
	
	var boss_scene = biome_settings.boss_scenes[randi() % biome_settings.boss_scenes.size()]
	var instance = boss_scene.instantiate()
	instance.global_position = ground_layer.map_to_local(pos)
	objects_node.add_child(instance)
	return true

func find_boss_spawn_position() -> Vector2i:
	var world_radius = world_generator.generation_settings.get("world_radius", 1000)
	var attempts = 200
	var spawn_radius = world_radius * 0.7
	var center = Vector2i.ZERO
	
	var noise_scale = 0.05
	var min_noise_value = 0.6
	
	for _i in range(attempts):
		var angle = randf_range(0, TAU)
		var distance = randf_range(spawn_radius * 0.5, spawn_radius)
		var pos = center + Vector2i(round(distance * cos(angle)), round(distance * sin(angle)))
		
		var main_noise = world_generator.noise_manager.get_cached_noise(pos)
		var main_terrain = world_generator.chunk_manager.find_biome(main_noise)
		
		var boss_noise = world_generator.noise_manager.get_density_noise(pos * noise_scale)
		
		if (is_valid_spawn_position(pos) && 
			boss_noise > min_noise_value):
			if is_position_clear(pos):
				return pos
	
	return Vector2i.ZERO

func is_position_clear(pos: Vector2i, min_distance: float = 500.0) -> bool:
	var check_pos = ground_layer.map_to_local(pos)
	for obj in objects_node.get_children():
		if obj.global_position.distance_to(check_pos) < min_distance:
			return false
	return true
