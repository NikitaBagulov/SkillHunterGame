extends EnemyState
class_name EnemyStateChase

# --- Настройки ---
## Имя анимации для состояния погони
@export var animation_name: String = "chase"
## Скорость преследования
@export var chase_speed: float = 20.0
## Скорость поворота (0.0 - 1.0)
@export var turn_rate: float = 0.25

# --- Настройки AI ---
@export_category("AI")
## Зона видимости врага
@export var vision_area: VisionArea
## Зона атаки врага
@export var attack_area: HurtBox
## Длительность состояния агрессии после потери игрока
@export var state_aggro_duration: float = 0.5
## Следующее состояние после завершения погони
@export var next_state: EnemyState

# --- Переменные ---
## Таймер состояния агрессии
var _aggro_timer: float = 0.0
## Направление движения
var _direction: Vector2 = Vector2.ZERO
## Флаг видимости игрока
var _can_see_player: bool = false

# --- Инициализация ---
func init() -> void:
	if vision_area:
		vision_area.player_entered.connect(_on_player_entered)
		vision_area.player_exited.connect(_on_player_exited)

# --- Управление состоянием ---
func enter() -> void:
	_aggro_timer = state_aggro_duration
	enemy.update_animation(animation_name)
	if attack_area:
		attack_area.monitoring = true

func exit() -> void:
	if attack_area:
		attack_area.monitoring = false
	_can_see_player = false

func process(delta: float) -> EnemyState:
	# Вычисляем направление к игроку и плавно поворачиваем
	var target_direction = enemy.global_position.direction_to(PlayerManager.player.global_position)
	_direction = _direction.lerp(target_direction, turn_rate)
	enemy.velocity = _direction * chase_speed
	
	if enemy.set_direction(_direction):
		enemy.update_animation(animation_name)
	
	# Управляем таймером агрессии
	if not _can_see_player:
		_aggro_timer -= delta
		if _aggro_timer <= 0:
			return next_state
	else:
		_aggro_timer = state_aggro_duration
	
	return null

# --- Обработчики событий ---
## Реакция на появление игрока в зоне видимости
func _on_player_entered() -> void:
	_can_see_player = true
	if state_machine.current_state is EnemyStateStun or state_machine.current_state is EnemyStateDestroy:
		return
	state_machine.change_state(self)

## Реакция на уход игрока из зоны видимости
func _on_player_exited() -> void:
	_can_see_player = false
