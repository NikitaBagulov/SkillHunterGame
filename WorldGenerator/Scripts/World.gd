class_name WorldGenerator extends Node2D

@onready var ground_layer = $GroundedLayer
@onready var biome_settings: BiomeSettings = $BiomeSettings

var tile_set

@export var generation_settings = {
	"chunk_size": Vector2i(8, 8),
	"render_distance": 4,
	"initial_load_distance": 1,
	"tile_scale": 1.0,
	"noise_type": FastNoiseLite.TYPE_PERLIN,
	"noise_frequency": 0.005,
	"noise_octaves": 3,
	"noise_seed": 0,
	"noise_offset": Vector2(0, 0),
	"chunk_cache_time": 120.0,
	"chunk_load_interval": 0.05,
	"density_noise_frequency": 0.05
}

var noise_manager = NoiseManager.new()
var chunk_manager = ChunkManager.new()
var object_spawner = ObjectSpawner.new()
var player_spawner = PlayerSpawner.new()

var player = PlayerManager.player
var last_player_chunk = Vector2i.ZERO
var objects_node: Node2D
var update_timer: Timer
var load_timer: Timer
var is_initialized: bool = false

func _ready():
	tile_set = ground_layer.tile_set
	add_child(noise_manager)
	add_child(chunk_manager)
	add_child(object_spawner)
	add_child(player_spawner)
	
	objects_node = Node2D.new()
	objects_node.name = "ObjectsNode"
	objects_node.y_sort_enabled = true
	add_child(objects_node)
	
	# Инициализация компонентов
	noise_manager.initialize(generation_settings)
	chunk_manager.initialize(self, ground_layer, generation_settings, biome_settings)
	object_spawner.initialize(self, objects_node, ground_layer, biome_settings)
	player_spawner.initialize(self)
	
	# Инициализация таймеров
	initialize_timers()
	
	# Отмечаем инициализацию завершённой
	is_initialized = true
	
	# Откладываем запуск мира
	if visible:
		start_world_deferred()
	else:
		stop_world()
	
	print("WorldGenerator: Initialized, visible: ", visible)

func initialize_timers():
	if not update_timer:
		update_timer = Timer.new()
		update_timer.wait_time = 0.5
		update_timer.connect("timeout", Callable(self, "check_player_position"))
		add_child(update_timer)
	
	if not load_timer:
		load_timer = Timer.new()
		load_timer.wait_time = generation_settings["chunk_load_interval"]
		load_timer.connect("timeout", Callable(chunk_manager, "load_next_chunk"))
		add_child(load_timer)
	
	print("WorldGenerator: Timers initialized")

func start_world_deferred():
	await get_tree().process_frame # Ждём кадр для завершения _ready
	start_world()
	print("WorldGenerator: Start world deferred")

func start_world():
	if not is_initialized:
		print("WorldGenerator: Not initialized yet, delaying start_world")
		return
	
	if not update_timer or not load_timer:
		initialize_timers()
	
	if update_timer.is_stopped():
		update_timer.start()
	if load_timer.is_stopped():
		load_timer.start()
	
	chunk_manager.resume_loading()
	start_initial_chunks()
	
	if PlayerManager.get_player() and visible:
		player_spawner.spawn_player()
		spawn_return_portal()
		if is_instance_valid(WorldCamera):
			WorldCamera.set_target(PlayerManager.get_player())
			WorldCamera.make_current()
	
	print("WorldGenerator: Started, timers active")

func stop_world():
	if update_timer and not update_timer.is_stopped():
		update_timer.stop()
	if load_timer and not update_timer.is_stopped():
		load_timer.stop()
	
	chunk_manager.pause_loading()
	print("WorldGenerator: Stopped, timers paused")

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			start_world_deferred()
		else:
			stop_world()
		print("WorldGenerator: Visibility changed to ", visible)

func start_initial_chunks():
	if not is_initialized:
		print("WorldGenerator: Skipping chunk generation, not initialized")
		return
	
	var render_distance = generation_settings["initial_load_distance"]
	var chunk_size = generation_settings["chunk_size"]
	
	for x in range(-render_distance, render_distance + 1):
		for y in range(-render_distance, render_distance + 1):
			var chunk_pos = Vector2i(x, y)
			if not chunk_manager.loaded_chunks.has(chunk_pos):
				chunk_manager.generate_chunk(chunk_pos)
	
	chunk_manager.loaded_chunks.clear()
	for x in range(-render_distance, render_distance + 1):
		for y in range(-render_distance, render_distance + 1):
			chunk_manager.loaded_chunks[Vector2i(x, y)] = true
	
	print("WorldGenerator: Initial chunks loaded")

func check_player_position():
	if not visible:
		return
	
	var player = PlayerManager.get_player()
	if not is_instance_valid(player):
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

func update_objects_visibility():
	if not visible:
		return
	
	for obj in objects_node.get_children():
		if is_instance_valid(obj):
			obj.visible = WorldCamera.is_in_view(obj.global_position)

func spawn_return_portal():
	var portal_scene = preload("res://GeneralNodes/Portal/Portal.tscn")
	var portal = portal_scene.instantiate()
	
	var hub_scene = preload("res://StartLocation/StartLocation.tscn")
	if not hub_scene:
		push_error("WorldGenerator: Failed to load hub scene at res://StartLocation/StartLocation.tscn")
		return
	
	portal.target_scene = hub_scene
	portal.spawn_position = Vector2(50, 50)
	portal.is_hub_to_world = false
	portal.portal_id = "world_to_hub_1"
	portal.global_position = Vector2(200, 200)
	
	if not is_instance_valid(objects_node):
		push_error("WorldGenerator: ObjectsNode is invalid or freed!")
		return
	
	objects_node.call_deferred("add_child", portal)
	print("WorldGenerator: Spawned return portal at ", portal.global_position, " with target scene: ", hub_scene.resource_path)
