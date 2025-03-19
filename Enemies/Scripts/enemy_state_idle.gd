extends EnemyState
class_name EnemyStateIdle

# --- Настройки ---
## Имя анимации для состояния покоя
@export var animation_name: String = "idle"

# --- Настройки AI ---
@export_category("AI")
## Минимальная длительность состояния
@export var state_duration_min: float = 0.5
## Максимальная длительность состояния
@export var state_duration_max: float = 1.5
## Следующее состояние после завершения
@export var after_idle_state: EnemyState

# --- Переменные ---
## Таймер состояния покоя
var _timer: float = 0.0

# --- Управление состоянием ---
func enter() -> void:
	enemy.velocity = Vector2.ZERO
	_timer = randf_range(state_duration_min, state_duration_max)
	enemy.update_animation(animation_name)

func process(delta: float) -> EnemyState:
	_timer -= delta
	if _timer <= 0:
		return after_idle_state
	return null
