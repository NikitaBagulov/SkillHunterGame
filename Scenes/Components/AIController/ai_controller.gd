# AIController.gd
extends Node

@export var speed: float = 100.0  # Скорость передвижения NPC
@export var patrol_radius: float = 200.0  # Радиус патрулирования от точки спавна
@export var pause_duration: float = 2.0  # Длительность паузы после достижения цели

@export var body: CharacterBody2D  # Ссылка на CharacterBody2D, к которому привязан компонент

var spawn_point: Vector2  # Точка спавна NPC
var current_target: Vector2  # Текущая цель патрулирования
var is_waiting: bool = false  # Флаг, указывающий, что NPC ждёт
var wait_timer: float = 0.0  # Таймер для паузы

func _ready():
	spawn_point = body.position  # Запоминаем точку спавна
	generate_new_target()  # Генерируем первую цель патрулирования

func _process(delta):
	if body:
		if is_waiting:
			wait_timer -= delta
			if wait_timer <= 0:
				is_waiting = false
				generate_new_target()
		else:
			patrol(delta)

func patrol(delta):
	var direction = (current_target - body.position).normalized()
	body.velocity = direction * speed
	body.move_and_slide()

	# Если NPC достиг цели, начинаем паузу
	if body.position.distance_to(current_target) < 10:
		start_waiting()

func start_waiting():
	is_waiting = true
	wait_timer = pause_duration
	body.velocity = Vector2.ZERO  # Останавливаем NPC

func generate_new_target():
	# Генерируем случайную точку в пределах patrol_radius от spawn_point
	var angle = randf() * 2 * PI  # Случайный угол
	var distance = randf() * patrol_radius  # Случайное расстояние
	current_target = spawn_point + Vector2(cos(angle), sin(angle)) * distance
