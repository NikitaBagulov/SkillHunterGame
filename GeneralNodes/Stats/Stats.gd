extends Resource
class_name Stats

# --- Сигналы ---
## Сигнал повышения уровня игрока
signal player_level_up(new_level: int)
## Сигнал обновления итогового урона
signal damage_updated(total_damage: int)

# --- Настройки ---
## Максимальное здоровье
@export var max_hp: int = 6
## Базовый урон
@export var base_damage: int = 1
## Текущий уровень
@export var level: int = 1
## Текущий опыт
@export var experience: int = 0
## Опыт, необходимый для следующего уровня
@export var exp_to_next_level: int = 10

# --- Переменные ---
## Текущее здоровье
var hp: int = max_hp
## Итоговый урон с учетом бонусов
var total_damage: int = base_damage

# --- Управление уроном ---
## Пересчитывает итоговый урон с учетом бонуса от оружия
func update_damage(weapon_bonus: int) -> void:
	total_damage = base_damage + weapon_bonus
	damage_updated.emit(total_damage)

# --- Управление опытом и уровнем ---
## Добавляет опыт и проверяет повышение уровня
func add_experience(amount: int) -> void:
	experience += amount
	while experience >= exp_to_next_level:
		_level_up()
	Inventory.stats_ui.update_stats(self)

## Повышает уровень игрока
func _level_up() -> void:
	experience -= exp_to_next_level
	level += 1
	exp_to_next_level = _calculate_next_level_exp()
	max_hp += 2
	hp = max_hp
	base_damage += 1
	player_level_up.emit(level)

## Вычисляет опыт для следующего уровня
func _calculate_next_level_exp() -> int:
	return int(exp_to_next_level * 1.5)

# --- Управление здоровьем ---
## Наносит урон игроку
func take_damage(amount: int) -> void:
	hp = clampi(hp - amount, 0, max_hp)
	Inventory.stats_ui.update_stats(self)

## Лечит игрока
func heal(amount: int) -> void:
	hp = clampi(hp + amount, 0, max_hp)
	Inventory.stats_ui.update_stats(self)
