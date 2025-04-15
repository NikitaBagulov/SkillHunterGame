class_name PlayerSpawner extends Node

var world_generator: WorldGenerator

func initialize(wg: WorldGenerator):
	world_generator = wg

func spawn_player():
	if world_generator.player:
		print("Игрок уже спавнен!")
		return
	var safe_position = find_safe_spawn_position()
	if safe_position:
		PlayerManager.spawn_player(world_generator)

		world_generator.player = PlayerManager.get_player()
		PlayerManager.set_player_position(safe_position)

		PlayerManager.set_player(world_generator.player)
		
		WorldCamera.global_position = safe_position  # Устанавливаем позицию камеры
		WorldCamera.make_current()  # Убеждаемся, что эта камера активна
		WorldCamera.force_update_scroll()
		#var bounds = world_generator.chunk_manager.get_current_bounds()
		#WorldCamera.update_limits(bounds)
		print("Камера центрирована на игроке в: ", safe_position)
		
		print("Игрок спавнен в: ", safe_position)
	else:
		print("Не удалось найти безопасную позицию для спавна!")

func find_safe_spawn_position() -> Vector2:
	var attempts = 1000
	var chunk_size = world_generator.generation_settings["chunk_size"]
	var player_chunk = world_generator.last_player_chunk
	
	for _i in range(attempts):
		var x = player_chunk.x * chunk_size.x + randi() % chunk_size.x
		var y = player_chunk.y * chunk_size.y + randi() % chunk_size.y
		var pos = Vector2i(x, y)
		var noise_value = world_generator.noise_manager.get_cached_noise(pos)
		var terrain_index = -1
		
		for biome in world_generator.biome_settings.biomes:
			if noise_value >= biome[2] and noise_value <= biome[3]:
				terrain_index = biome[0]
				break
		
		if terrain_index != 0:
			var world_pos = world_generator.ground_layer.map_to_local(pos)
			return world_pos
	
	print("Предупреждение: Не найдено безопасное место для спавна после ", attempts, " попыток!")
	return Vector2.ZERO
