extends Resource
class_name Stats

# --- Сигналы ---
signal player_level_up(stats: Stats)
signal damage_updated(total_damage: int)
signal health_updated(hp: int, max_hp: int)
signal position_updated(position: Vector2)  # Новый сигнал для обновления позиции

# --- Флаг инициализации ---
var _is_initialized: bool = false

# --- Настройки ---
@export var base_max_hp: int = 6 :
	get:
		return base_max_hp
	set(value):
		base_max_hp = max(value, 1)
		update_health(0)

var max_hp: int = base_max_hp :
	get:
		return max_hp
	set(value):
		max_hp = max(value, 1)
		hp = clampi(hp, 0, max_hp)
		health_updated.emit(hp, max_hp)

@export var base_damage: int = 1 :
	get:
		return base_damage
	set(value):
		base_damage = max(value, 0)
		if _is_initialized:
			update_damage(_get_weapon_bonus())
		else:
			total_damage = base_damage  # Временное значение до инициализации

@export var level: int = 1 :
	get:
		return level
	set(value):
		level = max(value, 1)

@export var experience: int = 0 :
	get:
		return experience
	set(value):
		experience = max(value, 0)
		while experience >= exp_to_next_level:
			_level_up()

@export var exp_to_next_level: int = 10 :
	get:
		return exp_to_next_level
	set(value):
		exp_to_next_level = max(value, 1)

# --- Новые свойства ---
## Позиция игрока
@export var position: Vector2 = Vector2.ZERO :
	get:
		return position
	set(value):
		position = value
		print("Stats.position set: ", position)
		position_updated.emit(position)

## Базовая скорость передвижения
@export var base_move_speed: float = 100.0 :
	get:
		return base_move_speed
	set(value):
		base_move_speed = max(value, 0.0)
		update_move_speed()

## Итоговая скорость передвижения (с учетом бонусов)
var move_speed: float = base_move_speed :
	get:
		return move_speed
	set(value):
		move_speed = max(value, 0.0)
		print("Stats.move_speed set: ", move_speed)

# --- Переменные ---
var hp: int = max_hp :
	get:
		return hp
	set(value):
		hp = clampi(hp, 0, max_hp)
		health_updated.emit(hp, max_hp)

var total_damage: int = base_damage :
	get:
		return total_damage
	set(value):
		total_damage = max(value, 0)
		damage_updated.emit(total_damage)

var speed_bonus: int = 0 :
	get:
		return speed_bonus
	set(value):
		speed_bonus = max(value, 0)
		update_move_speed()  # Обновляем итоговую скорость при изменении бонуса

# --- Инициализация ---
func init() -> void:
	
	update_damage(_get_weapon_bonus())
	update_health(_get_health_bonus())
	update_move_speed()
	if _is_initialized:
		return
	_is_initialized = true
	
	print("Stats initialized")

# --- Управление уроном ---
func update_damage(weapon_bonus: int) -> void:
	total_damage = base_damage + weapon_bonus
	damage_updated.emit(total_damage)

# --- Управление здоровьем ---
func update_health(health_bonus: int) -> void:
	var old_max_hp = max_hp
	max_hp = base_max_hp + health_bonus
	if old_max_hp > 0 and max_hp > old_max_hp:
		var hp_ratio = float(hp) / old_max_hp
		hp = int(max_hp * hp_ratio)
	else:
		hp = clampi(hp, 0, max_hp)
	print(health_bonus, " ", hp, " ", max_hp)
	health_updated.emit(hp, max_hp)

# --- Управление скоростью ---
func update_move_speed() -> void:
	move_speed = base_move_speed + speed_bonus
	print("Stats.update_move_speed: base=", base_move_speed, " bonus=", speed_bonus, " total=", move_speed)

func take_damage(amount: int) -> void:
	hp -= amount
	player_level_up.emit(self)

func heal(amount: int) -> void:
	hp += amount
	player_level_up.emit(self)

# --- Управление опытом и уровнем ---
func add_experience(amount: int) -> void:
	experience += amount
	player_level_up.emit(self)

func _level_up() -> void:
	experience -= exp_to_next_level
	level += 1
	exp_to_next_level = _calculate_next_level_exp()
	base_max_hp += 2
	hp = max_hp
	base_damage += 1
	base_move_speed += 5.0  # Увеличиваем базовую скорость при повышении уровня
	player_level_up.emit(self)
	if _is_initialized:
		update_health(_get_health_bonus())
	else:
		update_health(0)  # Без бонусов до инициализации

func _calculate_next_level_exp() -> int:
	return int(exp_to_next_level * 1.5)

# --- Вспомогательные методы ---
func _get_weapon_bonus() -> int:
	if PlayerManager and PlayerManager.INVENTORY_DATA:
		return PlayerManager.INVENTORY_DATA.get_equipped_weapon_damage_bonus()
	return 0

func _get_health_bonus() -> int:
	if PlayerManager and PlayerManager.INVENTORY_DATA:
		return PlayerManager.INVENTORY_DATA.get_health_bonus()
	return 0

# --- Сериализация и десериализация для сохранения ---
func serialize() -> Dictionary:
	return {
		"base_max_hp": base_max_hp,
		"max_hp": max_hp,
		"hp": hp,
		"base_damage": base_damage,
		"total_damage": total_damage,
		"level": level,
		"experience": experience,
		"exp_to_next_level": exp_to_next_level,
		"position": [position.x, position.y],  # Сохраняем Vector2 как массив
		"base_move_speed": base_move_speed,
		"move_speed": move_speed,
		"speed_bonus": speed_bonus
	}

func deserialize(data: Dictionary) -> void:
	base_max_hp = data.get("base_max_hp", 6)
	max_hp = data.get("max_hp", base_max_hp)
	hp = data.get("hp", max_hp)
	base_damage = data.get("base_damage", 1)
	total_damage = data.get("total_damage", base_damage)
	level = data.get("level", 1)
	experience = data.get("experience", 0)
	exp_to_next_level = data.get("exp_to_next_level", 10)
	var pos_array = data.get("position", [0.0, 0.0])
	position = Vector2(pos_array[0], pos_array[1])
	base_move_speed = data.get("base_move_speed", 100.0)
	move_speed = data.get("move_speed", base_move_speed)
	speed_bonus = data.get("speed_bonus", 0)
	
	# Вызываем сигналы для обновления UI или других систем
	health_updated.emit(hp, max_hp)
	damage_updated.emit(total_damage)
	position_updated.emit(position)
