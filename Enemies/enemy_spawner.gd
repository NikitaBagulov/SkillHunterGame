extends Area2D
class_name EnemySpawner

@export var biome: String = ""
@export var enemy_scenes: Array[PackedScene]
@export var max_enemies: int = 3
@export var spawn_radius: float = 50.0
@export var respawn_time: float = 10.0

var spawned_enemies: Array[Node] = []
var is_active: bool = false
var respawn_timer: SceneTreeTimer = null
@onready var spawn_container = get_parent()

func _ready() -> void:
	var shape = CircleShape2D.new()
	shape.radius = spawn_radius
	var collision = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	
	connect("area_entered", Callable(self, "_on_area_entered"))
	connect("area_exited", Callable(self, "_on_area_exited"))

func _exit_tree() -> void:
	if respawn_timer != null:
		respawn_timer = null
	for child in get_children():
		child.queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_spawn_zone"):
		is_active = true
		if spawned_enemies.is_empty():
			# Откладываем спавн врагов
			call_deferred("spawn_enemies")

func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("player_spawn_zone"):
		is_active = false
		for enemy in spawned_enemies.duplicate():
			if is_instance_valid(enemy):
				if enemy.is_connected("tree_exited", Callable(self, "_on_enemy_died")):
					enemy.disconnect("tree_exited", Callable(self, "_on_enemy_died"))
				enemy.queue_free()
		spawned_enemies.clear()

func spawn_enemies() -> void:
	if not is_active or spawned_enemies.size() >= max_enemies:
		return
	
	while spawned_enemies.size() < max_enemies:
		var enemy = create_enemy_instance()
		if enemy:
			# Откладываем добавление врага в сцену
			spawn_container.call_deferred("add_child", enemy)
			spawned_enemies.append(enemy)
			enemy.connect("tree_exited", Callable(self, "_on_enemy_died").bind(enemy), CONNECT_REFERENCE_COUNTED)

func create_enemy_instance() -> Node:
	if enemy_scenes.is_empty():
		return null
	
	var spawn_pos = global_position + Vector2(
		randf_range(-spawn_radius, spawn_radius),
		randf_range(-spawn_radius, spawn_radius)
	)
	
	for existing_enemy in spawned_enemies:
		if spawn_pos.distance_to(existing_enemy.global_position) < 16.0:
			return null
	
	var random_scene = enemy_scenes[randi() % enemy_scenes.size()]
	var instance = random_scene.instantiate()
	instance.global_position = spawn_pos
	if instance.has_method("set_target"):
		instance.set_target(PlayerManager.get_player())
	return instance

func _on_enemy_died(enemy: Node) -> void:
	spawned_enemies.erase(enemy)
	if is_active and spawned_enemies.is_empty():
		respawn_timer = get_tree().create_timer(respawn_time)
		await respawn_timer.timeout
		if is_active and is_instance_valid(self):
			spawn_enemies()
