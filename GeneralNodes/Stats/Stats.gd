class_name Stats extends Resource


# --- Сигналы ---
signal player_level_up(stats: Stats)
signal damage_updated(total_damage: int)
signal health_updated(hp: int, max_hp: int)
signal position_updated(position: Vector2)
signal currency_updated(currency: int)
signal experience_updated(stats: Stats)
signal player_died
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
			total_damage = base_damage

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
		experience_updated.emit(self)
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
		#print("Stats.position set: ", position)
		position_updated.emit(position)



@export var base_move_speed: float = 100.0 :
	get:
		return base_move_speed
	set(value):
		base_move_speed = max(value, 0.0)
		update_move_speed()

var move_speed: float = base_move_speed :
	get:
		return move_speed
	set(value):
		move_speed = max(value, 0.0)
		#print("Stats.move_speed set: ", move_speed)

# --- Новое поле для регенерации ---
@export var hp_regeneration_value: int = 1 :
	get:
		return hp_regeneration_value
	set(value):
		hp_regeneration_value = max(value, 0)
		#print("Stats.hp_regeneration_value set: ", hp_regeneration_value)

# --- Переменные ---
var hp: int = 1 :
	get:
		return hp
	set(value):
		hp = clampi(value, 0, max_hp)
		health_updated.emit(hp, max_hp)
		if value <=0:
			player_died.emit()

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
		update_move_speed()

var currency: int = 100 :
	get:
		return currency
	set(value):
		currency = max(value, 0)
		currency_updated.emit(currency)

# --- Инициализация ---
func init() -> void:
	update_damage(_get_weapon_bonus())
	update_health(_get_health_bonus())
	update_move_speed()
	update_regeneration(1)
	currency_updated.emit(currency)
	if _is_initialized:
		return
	_is_initialized = true
	#print("Stats initialized")

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
	#print(health_bonus, " ", hp, " ", max_hp)
	health_updated.emit(hp, max_hp)

# --- Управление скоростью ---
func update_move_speed() -> void:
	move_speed = base_move_speed + speed_bonus
	#print("Stats.update_move_speed: base=", base_move_speed, " bonus=", speed_bonus, " total=", move_speed)

# --- Управление регенерацией ---
func update_regeneration(regeneration_bonus: int) -> void:
	hp_regeneration_value = max(1, regeneration_bonus)  # Минимальное значение 1
	#print("Stats.hp_regeneration_value updated: ", hp_regeneration_value)

func take_damage(amount: int) -> void:
	hp -= amount
	health_updated.emit(hp, max_hp)  # Убрали лишний сигнал

func heal(amount: int) -> void:
	print("HP: ", hp, max_hp)
	hp += amount
	health_updated.emit(hp, max_hp)  # Убрали лишний сигнал

func add_currency(amount: int) -> void:
	currency += amount

func remove_currency(amount: int) -> bool:
	if currency >= amount:
		currency -= amount
		return true
	return false

# --- Управление опытом и уровнем ---
func add_experience(amount: int) -> void:
	experience += amount
	if experience >= exp_to_next_level:
		_level_up()

func _level_up() -> void:
	experience -= exp_to_next_level
	level += 1
	exp_to_next_level = _calculate_next_level_exp()
	base_max_hp += 2
	hp = max_hp
	base_damage += 1
	base_move_speed += 5.0
	hp_regeneration_value += 1  # Увеличиваем регенерацию при повышении уровня
	player_level_up.emit(self)
	if _is_initialized:
		update_health(_get_health_bonus())
	else:
		update_health(0)

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

# --- Сериализация и десериализация ---
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
		"position": [position.x, position.y],
		"base_move_speed": base_move_speed,
		"move_speed": move_speed,
		"speed_bonus": speed_bonus,
		"currency": currency,
		"hp_regeneration_value": hp_regeneration_value  # Добавили регенерацию
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
	currency = data.get("currency", 0)
	hp_regeneration_value = data.get("hp_regeneration_value", 1)  # Добавили регенерацию
	
	health_updated.emit(hp, max_hp)
	damage_updated.emit(total_damage)
	position_updated.emit(position)
	currency_updated.emit(currency)
