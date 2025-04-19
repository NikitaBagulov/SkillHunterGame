class_name BossExplosionState
extends BossState

@export var explosion_charge_scene: PackedScene  # Сцена заряда взрыва
@export var spawn_count: int = 3                 # Количество зарядов за раз
@export var spawn_radius: float = 200.0         # Радиус спавна
@export var duration: float = 2.0               # Длительность состояния

var timer: float = 0.0

func init() -> void:
	pass

func enter() -> void:
	boss.update_animation("idle")
	timer = duration
	# Спавним заряды
	for i in range(spawn_count):
		spawn_explosion_charge()

func process(delta: float) -> BossState:
	timer -= delta
	if timer <= 0.0:
		return state_machine.states[0]  # Возвращаемся в Idle
	return null

func physics(delta: float) -> BossState:
	# Босс не двигается
	boss.velocity = Vector2.ZERO
	return null

func exit() -> void:
	boss.velocity = Vector2.ZERO

func spawn_explosion_charge() -> void:
	if not explosion_charge_scene:
		return
	var charge = explosion_charge_scene.instantiate()
	# Случайная позиция в радиусе
	var angle = randf() * 2.0 * PI
	var distance = randf() * spawn_radius
	var offset = Vector2(cos(angle), sin(angle)) * distance
	charge.global_position = boss.global_position + offset
	# Добавляем заряд в сцену
	boss.get_tree().current_scene.add_child(charge)
	# Проверяем наличие AnimationPlayer
	if charge.has_node("AnimationPlayer"):
		var anim_player = charge.get_node("AnimationPlayer") as AnimationPlayer
		anim_player.play("spawn")
		await anim_player.animation_finished
		anim_player.play("explosion")
		await anim_player.animation_finished
		charge.queue_free()
