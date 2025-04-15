# PlayerSpawner.gd
@tool # Делает скрипт работающим в редакторе
extends Node2D

var spawn_position: Vector2 = self.position

@onready var global_player_manager = PlayerManager
@onready var sprite = $SpawnIndicator

func _ready() -> void:
	# Проверяем наличие индикатора спавна
	if not sprite:
		push_warning("PlayerSpawner: SpawnIndicator not found!")
	
	# Скрываем индикатор в игре
	if not Engine.is_editor_hint():
		if sprite:
			sprite.hide()
		else:
			print("PlayerSpawner: No sprite to hide in game mode")
	
	# Проверяем наличие GlobalPlayerManager
	if not global_player_manager:
		push_error("PlayerSpawner: GlobalPlayerManager not found! Ensure it's set up as an autoload.")
		return
	
	# Ждем готовности GlobalPlayerManager
	print("PlayerSpawner: Waiting for GlobalPlayerManager ready signal...")
	#if PlayerManager.player == null:
	spawn_player()
	global_player_manager.manager_ready.connect(_on_manager_ready)

func _on_manager_ready() -> void:
	print("PlayerSpawner: GlobalPlayerManager ready, initiating spawn...")
	spawn_player()

func spawn_player() -> void:
	# Проверяем наличие родительского узла
	var parent_node = get_parent()
	if not parent_node:
		push_error("PlayerSpawner: No parent node found for spawning player!")
		return
	
	# Используем GlobalPlayerManager для спавна игрока
	print("PlayerSpawner: Spawning player with parent node: ", parent_node.name)
	PlayerManager.spawn_player(parent_node)
	
	# Проверяем успешность спавна
	var player = PlayerManager.get_player()
	if player:
		print("PlayerSpawner: Player spawned successfully at ", player.position)
		PlayerManager.set_player_position(spawn_position)
	else:
		push_warning("PlayerSpawner: Failed to get player instance after spawn!")
		return
	
	# Настройка камеры
	if WorldCamera:
		print("PlayerSpawner: Setting WorldCamera position to ", spawn_position)
		WorldCamera.global_position = spawn_position
		WorldCamera.make_current()
		WorldCamera.force_update_scroll()
		
		if player:
			WorldCamera.set_target(player)
			print("PlayerSpawner: WorldCamera target set to player")
		else:
			push_warning("PlayerSpawner: Cannot set camera target, player is null")
	else:
		push_error("PlayerSpawner: WorldCamera not found! Ensure it's set up correctly.")

# Обновляет позицию спрайта в редакторе
func _update_sprite_position() -> void:
	if sprite:
		sprite.position = spawn_position
	else:
		if Engine.is_editor_hint():
			push_warning("PlayerSpawner: No SpawnIndicator sprite to update in editor!")

# Вызывается в редакторе при изменении свойств
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_update_sprite_position()
