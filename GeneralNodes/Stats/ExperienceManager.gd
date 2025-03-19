extends Node
class_name ExperienceManager

# --- Настройки ---
## Ссылка на статистику игрока
@export var stats: Stats

# --- Управление опытом ---
## Добавляет опыт игроку
func gain_experience(amount: int) -> void:
	if stats:
		stats.add_experience(amount)
		print("Experience gained: ", amount)
