extends Node
class_name ExperienceManager

# --- Настройки ---
## Ссылка на статистику игрока
var stats: Stats = PlayerManager.PLAYER_STATS

# --- Управление опытом ---
## Добавляет опыт игроку
func gain_experience(amount: int) -> void:
	if stats:
		stats.add_experience(amount)
		#print("Experience gained: ", amount)
