# EnemySpawner.gd
extends Area2D
class_name EnemySpawner

@export var biome: String = ""               # Биом, к которому привязан спавнер
@export var enemy_scenes: Array[PackedScene] # Сцены врагов для спавна
@export var max_enemies: int = 3             # Максимальное количество врагов
@export var spawn_radius: float = 50.0       # Радиус спавна (в пикселях)
@export var respawn_time: float = 10.0       # Время до респавна (в секундах)

var spawned_enemies: Array[Node] = []        # Список живых врагов
var is_active: bool = false                  # Активен ли спавнер (в зоне игрока)

func _ready() -> void:
	# Настраиваем CollisionShape2D для зоны действия спавнера
	var shape = CircleShape2D.new()
	shape.radius = spawn_radius
	var collision = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	
	# Подключаем сигналы для отслеживания пересечения с зоной игрока
	connect("area_entered", Callable(self, "_on_area_entered"))
	connect("area_exited", Callable(self, "_on_area_exited"))

# Активация спавнера при входе PlayerSpawnZone
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_spawn_zone"):
		is_active = true
		if spawned_enemies.is_empty():  # Спавним только если врагов ещё нет
			spawn_enemies()

# Деактивация спавнера при выходе PlayerSpawnZone
func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("player_spawn_zone"):
		is_active = false
		for enemy in spawned_enemies:
			enemy.queue_free()
		spawned_enemies.clear()

# Спавн врагов
func spawn_enemies() -> void:
	if not is_active or spawned_enemies.size() >= max_enemies:
		return
	
	while spawned_enemies.size() < max_enemies:
		var enemy = create_enemy_instance()
		if enemy:
			get_parent().add_child(enemy)  # Добавляем врага в родительский узел
			spawned_enemies.append(enemy)
			enemy.connect("tree_exited", Callable(self, "_on_enemy_died").bind(enemy))

# Создание экземпляра врага
func create_enemy_instance() -> Node:
	if enemy_scenes.is_empty():
		return null
	
	var spawn_pos = global_position + Vector2(
		randf_range(-spawn_radius, spawn_radius),
		randf_range(-spawn_radius, spawn_radius)
	)
	
	# Проверка минимального расстояния до других врагов
	for existing_enemy in spawned_enemies:
		if spawn_pos.distance_to(existing_enemy.global_position) < 16.0:
			return null
	
	var random_scene = enemy_scenes[randi() % enemy_scenes.size()]
	var instance = random_scene.instantiate()
	instance.global_position = spawn_pos
	if instance.has_method("set_target"):
		instance.set_target(PlayerManager.get_player())
	return instance

# Обработка смерти врага
func _on_enemy_died(enemy: Node) -> void:
	spawned_enemies.erase(enemy)
	if is_active and spawned_enemies.is_empty():
		await get_tree().create_timer(respawn_time).timeout
		if is_active:  # Проверяем, что игрок всё ещё в зоне
			spawn_enemies()
