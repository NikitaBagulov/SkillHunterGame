class_name BossIdleState
extends BossState

@export var min_duration: float = 2.0
@export var max_duration: float = 4.0
@export var move_speed: float = 500.0
@export var direction_change_interval: float = 1.0

@export var next_states: Array[BossState] = []  # Теперь массив задаётся через export

var timer: float = 0.0
var direction_change_timer: float = 0.0
var current_direction: Vector2 = Vector2.RIGHT
var current_state_index: int = 0  # Новая переменная для отслеживания индекса

func init() -> void:
	pass

func enter() -> void:
	boss.update_animation("idle")
	timer = randf_range(min_duration, max_duration)
	direction_change_timer = direction_change_interval
	#current_state_index = 0  # Сброс индекса при входе в состояние
	
	# Инициализация направления (оставлено как было)
	if boss.player:
		current_direction = (boss.player.global_position - boss.global_position).normalized()
	else:
		current_direction = Vector2.RIGHT if randf() > 0.5 else Vector2.LEFT
	boss.set_direction(current_direction)

func process(delta: float) -> BossState:
	timer -= delta
	if timer <= 0.0:
		# Теперь выбираем следующее состояние из next_states по порядку
		if next_states.size() > 0:
			var next_state := next_states[current_state_index]
			current_state_index = (current_state_index + 1) % next_states.size()  # Циклический переход
			return next_state
		else:
			# Если массив пуст, не переходим
			return null
	return null

func physics(delta: float) -> BossState:
	direction_change_timer -= delta
	if direction_change_timer <= 0.0:
		if boss.player:
			var target_direction = (boss.player.global_position - boss.global_position).normalized()
			var new_direction_x = Vector2.RIGHT if target_direction.x >= 0 else Vector2.LEFT
			if new_direction_x != current_direction:
				current_direction = new_direction_x
				boss.set_direction(current_direction)
		else:
			current_direction = Vector2.RIGHT if randf() > 0.5 else Vector2.LEFT
			boss.set_direction(current_direction)
		direction_change_timer = direction_change_interval
	
	boss.velocity = current_direction * move_speed
	return null

func exit() -> void:
	boss.velocity = Vector2.ZERO
