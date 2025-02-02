# PlayerController.gd
extends Node

@export var speed: float = 200.0  # Скорость передвижения игрока
@export var body: CharacterBody2D  # Ссылка на CharacterBody2D, к которому привязан компонент
@export var camera: Camera2D  # Ссылка на камеру
@export var animation_component: AnimationComponent

func _process(delta):
	if body:
		move_player(delta)

func _input(event):
	# Обработка колесика мыши
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:  # Колесико вверх
			camera.zoom_camera(1)  # Приближение
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:  # Колесико вниз
			camera.zoom_camera(-1)  # Удаление

func move_player(delta):
	var direction = Vector2.ZERO
	var is_moving = false
	var last_direction = Vector2.ZERO

	# Управление с клавиатуры
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
		body.get_node("Sprite2D").flip_h = false
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
		body.get_node("Sprite2D").flip_h = true
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1

	# Определяем движение и основное направление
	is_moving = direction != Vector2.ZERO
	if is_moving:
		# Сохраняем ненормализованное направление для точного определения
		last_direction = direction.snapped(Vector2.ONE)

	# Нормализация вектора направления
	direction = direction.normalized()
	body.velocity = direction * speed
	body.move_and_slide()

	# Управление анимациями
	if is_moving:
		# Определяем преобладающее направление с порогом
		if abs(direction.x) > abs(direction.y) + 0.1:
			animation_component.play("walk_right_left")
		else:
			if direction.y > 0:
				animation_component.play("walk_down")
			else:
				animation_component.play("walk_up")
	else:
		# Воспроизводим idle-анимацию в последнем направлении
		if last_direction != Vector2.ZERO:
			if abs(last_direction.x) > abs(last_direction.y) + 0.1:
				animation_component.play("idle_right_left")
			else:
				if last_direction.y > 0:
					animation_component.play("idle_down")
				else:
					animation_component.play("idle_up")
		else:
			animation_component.play("idle_right_left")
