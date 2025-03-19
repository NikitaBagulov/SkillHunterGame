extends Area2D
class_name EnemySpawner

# --- Настройки ---
## Биом, связанный со спавнером
@export var biome: String = ""
## Список сцен врагов для спавна
@export var enemy_scenes: Array[PackedScene] = []
## Максимальное количество врагов
@export var max_enemies: int = 3
## Радиус области спавна
@export var spawn_radius: float = 50.0
## Время возрождения врагов (в секундах)
@export var respawn_time: float = 10.0

# --- Переменные ---
## Список текущих spawned врагов
var spawned_enemies: Array[Node] = []
## Активность спавнера
var is_active: bool = false
## Таймер возрождения
var respawn_timer: SceneTreeTimer = null
## Контейнер для spawned врагов
@onready var spawn_container = get_parent()

# --- Инициализация ---
func _ready() -> void:
	_setup_collision_shape()
	# Подключаем сигналы обнаружения зон
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

## Настраивает форму столкновения для области спавна
func _setup_collision_shape() -> void:
	var shape = CircleShape2D.new()
	shape.radius = spawn_radius
	var collision = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

# --- Очистка ---
func _exit_tree() -> void:
	# Очищаем таймер и дочерние узлы при выходе из дерева
	respawn_timer = null
	for child in get_children():
		child.queue_free()

# --- Обработчики событий ---
## Активирует спавнер при входе игрока
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_spawn_zone"):
		is_active = true
		if spawned_enemies.is_empty():
			call_deferred("spawn_enemies")

## Деактивирует спавнер и удаляет врагов при выходе игрока
func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("player_spawn_zone"):
		is_active = false
		_clear_enemies()

# --- Управление врагами ---
## Создает и размещает врагов в зоне спавна
func spawn_enemies() -> void:
	if not is_active or spawned_enemies.size() >= max_enemies:
		return
	
	while spawned_enemies.size() < max_enemies:
		var enemy = _create_enemy_instance()
		if enemy:
			spawn_container.call_deferred("add_child", enemy)
			spawned_enemies.append(enemy)
			enemy.connect("tree_exited", _on_enemy_died.bind(enemy), CONNECT_REFERENCE_COUNTED)

## Создает экземпляр врага с учетом дистанции
func _create_enemy_instance() -> Node:
	if enemy_scenes.is_empty():
		return null
	
	var spawn_pos = global_position + Vector2(
		randf_range(-spawn_radius, spawn_radius),
		randf_range(-spawn_radius, spawn_radius)
	)
	
	for enemy in spawned_enemies:
		if spawn_pos.distance_to(enemy.global_position) < 16.0:
			return null
	
	var scene = enemy_scenes[randi() % enemy_scenes.size()]
	var instance = scene.instantiate()
	instance.global_position = spawn_pos
	
	if instance.has_method("set_target"):
		instance.set_target(PlayerManager.get_player())
	return instance

## Обрабатывает смерть врага и запускает таймер возрождения
func _on_enemy_died(enemy: Node) -> void:
	spawned_enemies.erase(enemy)
	if is_active and spawned_enemies.is_empty():
		_start_respawn_timer()

## Очищает всех врагов из списка и сцены
func _clear_enemies() -> void:
	for enemy in spawned_enemies.duplicate():
		if is_instance_valid(enemy):
			if enemy.is_connected("tree_exited", _on_enemy_died):
				enemy.disconnect("tree_exited", _on_enemy_died)
			enemy.queue_free()
	spawned_enemies.clear()

## Запускает таймер для возрождения врагов
func _start_respawn_timer() -> void:
	respawn_timer = get_tree().create_timer(respawn_time)
	await respawn_timer.timeout
	if is_active and is_instance_valid(self):
		spawn_enemies()
