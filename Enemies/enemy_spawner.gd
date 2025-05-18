extends Area2D
class_name EnemySpawner

# --- Settings ---
## Biome associated with the spawner
@export var biome: String = ""
## List of enemy scenes to spawn
@export var enemy_scenes: Array[PackedScene] = []
## Maximum number of enemies
@export var max_enemies: int = 3
## Radius of the spawn area
@export var spawn_radius: float = 50.0
## Respawn time for enemies (in seconds)
@export var respawn_time: float = 10.0
## Difficulty multiplier affecting enemy stats
@export var difficulty: float = 1.0

# --- Variables ---
## List of currently spawned enemies
var spawned_enemies: Array[Node] = []
## Spawner activity status
var is_active: bool = false
## Respawn timer
var respawn_timer: SceneTreeTimer = null
## Container for spawned enemies
@onready var spawn_container = get_parent()

# --- Initialization ---
func _ready() -> void:
	_setup_collision_shape()
	# Connect area detection signals
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

## Sets up the collision shape for the spawn area
func _setup_collision_shape() -> void:
	var shape = CircleShape2D.new()
	shape.radius = spawn_radius
	var collision = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

# --- Cleanup ---
func _exit_tree() -> void:
	# Clear timer and child nodes on tree exit
	respawn_timer = null
	for child in get_children():
		child.queue_free()

# --- Event Handlers ---
## Activates spawner when player enters
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_spawn_zone"):
		is_active = true
		if spawned_enemies.is_empty():
			call_deferred("spawn_enemies")

## Deactivates spawner and removes enemies when player exits
func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("player_spawn_zone"):
		is_active = false
		_clear_enemies()

# --- Enemy Management ---
## Creates and places enemies in the spawn area
func spawn_enemies() -> void:
	if not is_active or spawned_enemies.size() >= max_enemies:
		return
	
	while spawned_enemies.size() < max_enemies:
		var enemy = _create_enemy_instance()
		if enemy:
			spawn_container.call_deferred("add_child", enemy)
			spawned_enemies.append(enemy)
			enemy.connect("tree_exited", _on_enemy_died.bind(enemy), CONNECT_REFERENCE_COUNTED)

## Creates an enemy instance with distance considerations
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
	instance.difficulty = difficulty
	
	if instance.has_method("set_target"):
		instance.set_target(PlayerManager.get_player())
	return instance

## Handles enemy death and starts respawn timer
func _on_enemy_died(enemy: Node) -> void:
	spawned_enemies.erase(enemy)
	if is_active and spawned_enemies.is_empty():
		_start_respawn_timer()

## Clears all enemies from the list and scene
func _clear_enemies() -> void:
	for enemy in spawned_enemies.duplicate():
		if is_instance_valid(enemy):
			if enemy.is_connected("tree_exited", _on_enemy_died):
				enemy.disconnect("tree_exited", _on_enemy_died)
			enemy.queue_free()
	spawned_enemies.clear()

## Starts timer for enemy respawn
func _start_respawn_timer() -> void:
	respawn_timer = get_tree().create_timer(respawn_time)
	await respawn_timer.timeout
	if is_active and is_instance_valid(self):
		spawn_enemies()
