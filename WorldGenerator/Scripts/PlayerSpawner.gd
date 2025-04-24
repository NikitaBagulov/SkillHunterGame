class_name PlayerSpawner extends Node

var world_generator: WorldGenerator

func initialize(wg: WorldGenerator):
	world_generator = wg

func spawn_player():
	if world_generator.player:
		#print("Игрок уже спавнен!")
		return
	var safe_position = self.global_position
	if safe_position:
		PlayerManager.spawn_player(world_generator)

		world_generator.player = PlayerManager.get_player()
		PlayerManager.set_player_position(safe_position)

		PlayerManager.set_player(PlayerManager.player)
		
		WorldCamera.global_position = safe_position  # Устанавливаем позицию камеры
		WorldCamera.make_current()  # Убеждаемся, что эта камера активна
		WorldCamera.force_update_scroll()


func find_safe_spawn_position() -> Vector2:
	var attempts = 1000
	var chunk_size = world_generator.generation_settings["chunk_size"]
	var player_chunk = world_generator.last_player_chunk
	
	for _i in range(attempts):
		var x = player_chunk.x * chunk_size.x + randi() % chunk_size.x
		var y = player_chunk.y * chunk_size.y + randi() % chunk_size.y
		var pos = Vector2i(x, y)
		
		var noise_value = world_generator.noise_manager.get_cached_noise(pos)
		
		# Определим, является ли это безопасной зоной по шуму
		if is_safe_noise_value(noise_value):
			# Просто преобразуем тайловую позицию в мировую
			return pos * world_generator.ground_layer.tile_set.tile_size
	
	return Vector2.ZERO  # Если не нашлось безопасного места

func is_safe_noise_value(noise_value: float) -> bool:
	# Биомы с terrain_index = 0 считаются водой, они небезопасны
	for biome in world_generator.biome_settings.biomes:
		if noise_value >= biome[2] and noise_value <= biome[3]:
			return biome[0] != 0  # Только не-вода
	return false
