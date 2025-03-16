class_name WorldGenerator extends Node2D

@onready var ground_layer = $GroundedLayer
@onready var biome_settings: BiomeSettings = $BiomeSettings

var tile_set

@export var generation_settings = {
	"chunk_size": Vector2i(8, 8),
	"render_distance": 4,           # Полный радиус загрузки
	"initial_load_distance": 1,     # Начальный радиус загрузки (3x3 чанка)
	"tile_scale": 1.0,
	"noise_type": FastNoiseLite.TYPE_PERLIN,
	"noise_frequency": 0.005,
	"noise_octaves": 3,
	"noise_seed": 0,
	"noise_offset": Vector2(0, 0),
	"chunk_cache_time": 120.0,
	"chunk_load_interval": 0.05,    # Увеличим интервал для плавности
	"density_noise_frequency": 0.05
}

var noise_manager = NoiseManager.new()
var chunk_manager = ChunkManager.new()
var object_spawner = ObjectSpawner.new()
var player_spawner = PlayerSpawner.new()

var player = null
var last_player_chunk = Vector2i.ZERO
var objects_node: Node2D
var progress_bar: ProgressBar  # Прогресс-бар для отображения загрузки

func _ready():
	tile_set = ground_layer.tile_set
	add_child(noise_manager)
	add_child(chunk_manager)
	add_child(object_spawner)
	add_child(player_spawner)
	
	objects_node = Node2D.new()
	objects_node.name = "ObjectsNode"
	objects_node.y_sort_enabled = true  # Включаем Y-сортировку для объектов
	add_child(objects_node)
	
	noise_manager.initialize(generation_settings)
	chunk_manager.initialize(self, ground_layer, generation_settings, biome_settings)
	object_spawner.initialize(self, objects_node, ground_layer, biome_settings)  # Исправлено: objects_node вместо self
	player_spawner.initialize(self)
	
	WorldCamera.make_current()
	
	# Таймеры для обновления мира
	var update_timer = Timer.new()
	update_timer.wait_time = 0.5
	update_timer.connect("timeout", Callable(self, "check_player_position"))
	add_child(update_timer)
	update_timer.start()
	
	var load_timer = Timer.new()
	load_timer.wait_time = generation_settings["chunk_load_interval"]
	load_timer.connect("timeout", Callable(chunk_manager, "load_next_chunk"))
	add_child(load_timer)
	load_timer.start()
	
	# Ждём загрузки начальных чанков и спавним игрока
	# Показываем экран загрузки и ждём генерации
	SceneLoadingScreen.show_loading()
	await load_initial_chunks()
	player_spawner.spawn_player()
	WorldCamera.set_target(player)

func load_initial_chunks() -> void:
	var render_distance = generation_settings["render_distance"]
	var chunk_size = generation_settings["chunk_size"]
	var total_chunks = (2 * render_distance + 1) * (2 * render_distance + 1)
	var loaded_chunks = 0
	
	for x in range(-render_distance, render_distance + 1):
		for y in range(-render_distance, render_distance + 1):
			var chunk_pos = Vector2i(x, y)
			if not chunk_manager.loaded_chunks.has(chunk_pos):
				chunk_manager.generate_chunk(chunk_pos)
				loaded_chunks += 1
				SceneLoadingScreen.set_progress((float(loaded_chunks) / total_chunks) * 100)
				await get_tree().create_timer(0.01).timeout  # Плавность UI
	
	# Обновляем список загруженных чанков
	chunk_manager.loaded_chunks.clear()
	for x in range(-render_distance, render_distance + 1):
		for y in range(-render_distance, render_distance + 1):
			chunk_manager.loaded_chunks[Vector2i(x, y)] = true

func check_player_position():
	if not player:
		return
	var player_pos = player.global_position / (tile_set.tile_size * generation_settings["tile_scale"])
	var player_chunk = Vector2i(floor(player_pos.x / generation_settings["chunk_size"].x),
								floor(player_pos.y / generation_settings["chunk_size"].y))
	if player_chunk != last_player_chunk:
		last_player_chunk = player_chunk
		chunk_manager.update_chunks(player_chunk)
	if ground_layer is LevelTileMap:
		ground_layer.update_bounds()
	update_objects_visibility()

# Новый метод для обновления видимости
func update_objects_visibility():
	for obj in objects_node.get_children():
		if is_instance_valid(obj):
			obj.visible = WorldCamera.is_in_view(obj.global_position)
