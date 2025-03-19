extends EnemyState
class_name EnemyStateWander

# --- Настройки ---
## Имя анимации для состояния блуждания
@export var animation_name: String = "walk"
## Скорость движения при блуждании
@export var wander_speed: float = 20.0

# --- Настройки AI ---
@export_category("AI")
## Длительность одного цикла анимации
@export var state_animation_duration: float = 0.5
## Минимальное количество циклов блуждания
@export var state_cycles_min: int = 1
## Максимальное количество циклов блуждания
@export var state_cycles_max: int = 3
## Следующее состояние после блуждания
@export var next_state: EnemyState

# --- Переменные ---
## Таймер длительности состояния
var _timer: float = 0.0
## Направление движения
var _direction: Vector2 = Vector2.ZERO

# --- Управление состоянием ---
func enter() -> void:
	# Устанавливаем случайную длительность состояния
	_timer = randi_range(state_cycles_min, state_cycles_max) * state_animation_duration
	
	# Выбираем случайное направление из доступных
	var rand_index = randi_range(0, enemy.DIRECTIONS.size() - 1)
	_direction = enemy.DIRECTIONS[rand_index]
	
	enemy.velocity = _direction * wander_speed
	enemy.set_direction(_direction)
	enemy.update_animation(animation_name)

func process(delta: float) -> EnemyState:
	_timer -= delta
	if _timer <= 0:
		return next_state
	return null
