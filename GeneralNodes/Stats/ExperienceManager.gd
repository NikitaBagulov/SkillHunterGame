# ExperienceManager.gd
extends Node
class_name ExperienceManager

@export var stats: Stats  # Ссылка на Stats игрока

func _ready() -> void:
	pass

func gain_experience(amount: int) -> void:
	if stats:
		stats.add_experience(amount)
		print("Получено опыта:", amount)

# Убираем connect_to_enemy и _on_enemy_destroyed, так как они больше не нужны
