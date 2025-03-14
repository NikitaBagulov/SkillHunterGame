# PlayerSpawnZone.gd
extends Area2D
class_name PlayerSpawnZone

@export var radius: float = 200.0  # Радиус зоны активации

func _ready() -> void:
	# Настраиваем CollisionShape2D
	var shape = CircleShape2D.new()
	shape.radius = radius
	var collision = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	add_to_group("player_spawn_zone")
	
