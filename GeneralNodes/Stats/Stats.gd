extends Resource
class_name Stats

# --- Сигналы ---
## Сигнал повышения уровня игрока
signal player_level_up(new_level: int)
## Сигнал обновления итогового урона
signal damage_updated(total_damage: int)

# --- Настройки ---
## Максимальное здоровье
@export var max_hp: int = 6 : 
	get:
		return max_hp
	set(value):
		max_hp = max(value, 1)  # Не допускаем значения меньше 1
		hp = clampi(hp, 0, max_hp)  # Корректируем текущее здоровье

## Базовый урон
@export var base_damage: int = 1 :
	get:
		return base_damage
	set(value):
		base_damage = max(value, 0)  # Не допускаем отрицательного урона
		# total_damage пересчитывается только через update_damage

## Текущий уровень
@export var level: int = 1 :
	get:
		return level
	set(value):
		level = max(value, 1)  # Уровень не может быть меньше 1

## Текущий опыт
@export var experience: int = 0 :
	get:
		return experience
	set(value):
		experience = max(value, 0)  # Опыт не может быть отрицательным
		while experience >= exp_to_next_level:
			_level_up()

## Опыт, необходимый для следующего уровня
@export var exp_to_next_level: int = 10 :
	get:
		return exp_to_next_level
	set(value):
		exp_to_next_level = max(value, 1)  # Не допускаем значения меньше 1

# --- Переменные ---
## Текущее здоровье
var hp: int = max_hp :
	get:
		return hp
	set(value):
		hp = clampi(value, 0, max_hp)

## Итоговый урон с учетом бонусов
var total_damage: int = base_damage :
	get:
		return total_damage
	set(value):
		total_damage = max(value, 0)  # Не допускаем отрицательного урона
		damage_updated.emit(total_damage)

## Бонус скорости
var speed_bonus: int = 0 :
	get:
		return speed_bonus
	set(value):
		speed_bonus = max(value, 0)  # Не допускаем отрицательного бонуса скорости

# --- Управление уроном ---
## Пересчитывает итоговый урон с учетом бонуса от оружия
func update_damage(weapon_bonus: int) -> void:
	total_damage = base_damage + weapon_bonus
	damage_updated.emit(total_damage)

# --- Управление опытом и уровнем ---
## Добавляет опыт и проверяет повышение уровня
func add_experience(amount: int) -> void:
	experience += amount  # Используем сеттер

## Повышает уровень игрока
func _level_up() -> void:
	experience -= exp_to_next_level
	level += 1
	exp_to_next_level = _calculate_next_level_exp()
	max_hp += 2  # Используем сеттер
	hp = max_hp  # Используем сеттер
	base_damage += 1  # Используем сеттер
	player_level_up.emit(level)

## Вычисляет опыт для следующего уровня
func _calculate_next_level_exp() -> int:
	return int(exp_to_next_level * 1.5)

# --- Управление здоровьем ---
## Наносит урон игроку
func take_damage(amount: int) -> void:
	hp -= amount  # Используем сеттер

## Лечит игрока
func heal(amount: int) -> void:
	hp += amount  # Используем сеттер
