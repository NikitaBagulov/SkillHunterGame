extends EnemyState
class_name EnemyStateStun

# --- Настройки ---
## Имя анимации для состояния оглушения
@export var animation_name: String = "stun"
## Скорость отбрасывания при оглушении
@export var knockback_speed: float = 200.0
## Скорость замедления после отбрасывания
@export var decelerate_speed: float = 10.0

# --- Настройки AI ---
@export_category("AI")
## Следующее состояние после оглушения
@export var next_state: EnemyState

# --- Переменные ---
## Позиция источника урона
var _damage_position: Vector2
## Направление отбрасывания
var _direction: Vector2
## Флаг завершения анимации
var _animation_finished: bool = false

# --- Инициализация ---
func init() -> void:
	enemy.enemy_damaged.connect(_on_enemy_damaged)

# --- Управление состоянием ---
func enter() -> void:
	enemy.invulnerable = true
	_animation_finished = false
	
	_direction = enemy.global_position.direction_to(_damage_position)
	enemy.set_direction(_direction)
	enemy.velocity = _direction * -knockback_speed
	
	enemy.update_animation(animation_name)
	enemy.animation_player.animation_finished.connect(_on_animation_finished)

func exit() -> void:
	enemy.invulnerable = false
	enemy.animation_player.animation_finished.disconnect(_on_animation_finished)

func process(delta: float) -> EnemyState:
	if _animation_finished:
		return next_state
	enemy.velocity -= enemy.velocity * decelerate_speed * delta
	return null

# --- Обработчики событий ---
## Реакция на получение урона врагом
func _on_enemy_damaged(hurt_box: HurtBox) -> void:
	_damage_position = hurt_box.global_position
	state_machine.change_state(self)

## Установка флага завершения анимации
func _on_animation_finished(_animation: String) -> void:
	_animation_finished = true
