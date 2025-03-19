extends Area2D
class_name PlayerSpawnZone

# --- Настройки ---
## Радиус зоны активации
@export var radius: float = 200.0

# --- Инициализация ---
func _ready() -> void:
	_setup_collision_shape()
	add_to_group("player_spawn_zone")

# --- Вспомогательные методы ---
## Настраивает CollisionShape2D для зоны активации
func _setup_collision_shape() -> void:
	var shape = CircleShape2D.new()
	shape.radius = radius
	var collision = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
