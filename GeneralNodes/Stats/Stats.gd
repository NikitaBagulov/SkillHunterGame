# Stats.gd
extends Resource
class_name Stats

signal player_level_up(new_level: int)  # Сигнал при повышении уровня

@export var max_hp: int = 6      # Максимальное здоровье
@export var base_damage: int = 1 # Базовый урон
@export var level: int = 1       # Текущий уровень
@export var experience: int = 0  # Текущий опыт
@export var exp_to_next_level: int = 10  # Опыт для следующего уровня

var hp: int = max_hp  # Текущее здоровье

func add_experience(amount: int) -> void:
	experience += amount
	while experience >= exp_to_next_level:
		level_up()
	Inventory.stats_ui.update_stats(self)  # Обновляем UI

func level_up() -> void:
	experience -= exp_to_next_level
	level += 1
	exp_to_next_level = calculate_next_level_exp()  # Увеличиваем требуемый опыт
	max_hp += 2  # Увеличиваем здоровье на 2
	hp = max_hp  # Полное восстановление здоровья
	base_damage += 1  # Увеличиваем урон на 1
	emit_signal("player_level_up", level)

func calculate_next_level_exp() -> int:
	return int(exp_to_next_level * 1.5)  # Увеличиваем опыт на 50% для следующего уровня

func take_damage(amount: int) -> void:
	hp = clampi(hp - amount, 0, max_hp)
	Inventory.stats_ui.update_stats(self)

func heal(amount: int) -> void:
	hp = clampi(hp + amount, 0, max_hp)
	Inventory.stats_ui.update_stats(self)
