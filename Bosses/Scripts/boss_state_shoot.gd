class_name ShootProjectilesState
extends BossState

@export var projectile_scene: PackedScene  # Сцена снаряда
@export var projectile_count: int = 4      # Количество выстрелов
@export var shoot_interval: float = 0.5    # Интервал между выстрелами
@export var duration: float = 2.0          # Длительность состояния

var timer: float = 0.0
var shoot_timer: float = 0.0
var shots_fired: int = 0

func init() -> void:
	pass

func enter() -> void:
	boss.update_animation("idle")
	timer = duration
	shoot_timer = shoot_interval
	shots_fired = 0

func process(delta: float) -> BossState:
	timer -= delta
	shoot_timer -= delta
	if shoot_timer <= 0.0 and shots_fired < projectile_count:
		shoot_projectile()
		shots_fired += 1
		shoot_timer = shoot_interval
	if timer <= 0.0:
		return state_machine.states[0]  # Возвращаемся в Idle
	return null

func physics(delta: float) -> BossState:
	# Босс не двигается
	boss.velocity = Vector2.ZERO
	return null

func exit() -> void:
	boss.velocity = Vector2.ZERO

func shoot_projectile() -> void:
	if not projectile_scene or not boss.player:
		return
	# Спавним снаряд из каждой точки
	for i in range(4):  # 4 точки спавна
		var projectile = projectile_scene.instantiate()
		projectile.global_position = boss.get_projectile_spawn_position(i)
		var direction = (boss.player.global_position - projectile.global_position).normalized()
		if projectile.has_method("set_direction"):
			projectile.set_direction(direction)
		boss.get_tree().current_scene.add_child(projectile)
		projectile.animation_player.play("spawn")
