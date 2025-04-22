class_name BossIdleState
extends BossState

@export var min_duration: float = 2.0  # Минимальное время в состоянии (сек)
@export var max_duration: float = 4.0  # Максимальное время в состоянии (сек)
@export var move_speed: float = 500.0   # Скорость движения
@export var direction_change_interval: float = 1.0  # Интервал смены направления (сек)

var timer: float = 0.0
var possible_states: Array[BossState] = []
var direction_change_timer: float = 0.0  # Таймер для смены направления
var current_direction: Vector2 = Vector2.RIGHT  # Текущее направление движения

func init() -> void:
	pass

func enter() -> void:
	boss.update_animation("idle")
	timer = randf_range(min_duration, max_duration)
	direction_change_timer = direction_change_interval
	# Инициализируем направление
	if boss.player:
		current_direction = (boss.player.global_position - boss.global_position).normalized()
	else:
		current_direction = Vector2.RIGHT if randf() > 0.5 else Vector2.LEFT
	boss.set_direction(current_direction)
	# Собираем возможные состояния для перехода (кроме текущего)
	possible_states.clear()
	for state in state_machine.states:
		if state != self:
			possible_states.append(state)

func process(delta: float) -> BossState:
	timer -= delta
	if timer <= 0.0:
		# Случайно выбираем следующее состояние
		return possible_states[randi() % possible_states.size()]
	return null

func physics(delta: float) -> BossState:
	# Обновляем таймер смены направления
	direction_change_timer -= delta
	
	# Проверяем, можно ли сменить направление
	if direction_change_timer <= 0.0:
		if boss.player:
			# Двигаемся к игроку с небольшой задержкой
			var target_direction = (boss.player.global_position - boss.global_position).normalized()
			# Сглаживаем направление (используем только X для двух направлений)
			var new_direction_x = Vector2.RIGHT if target_direction.x >= 0 else Vector2.LEFT
			if new_direction_x != current_direction:
				current_direction = new_direction_x
				boss.set_direction(current_direction)
		else:
			# Случайное направление, если игрока нет
			current_direction = Vector2.RIGHT if randf() > 0.5 else Vector2.LEFT
			boss.set_direction(current_direction)
		direction_change_timer = direction_change_interval
	
	# Устанавливаем скорость
	boss.velocity = current_direction * move_speed
	return null

func exit() -> void:
	boss.velocity = Vector2.ZERO
