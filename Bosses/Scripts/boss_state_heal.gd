class_name BossHealState
extends BossState

@export var heal_amount: int = 10       # Количество восстанавливаемого здоровья
@export var duration: float = 1.5       # Длительность состояния

var timer: float = 0.0

func init() -> void:
	pass

func enter() -> void:
	# Воспроизводим анимацию heal
	boss.animation_player.play("heal")
	timer = duration
	# Применяем лечение
	await boss.animation_player.animation_finished
	boss.change_health(heal_amount)
	print("Boss healed, HP: ", boss.HP)

func process(delta: float) -> BossState:
	timer -= delta
	if timer <= 0.0:
		return state_machine.states[0]  # Возвращаемся в Idle
	return null

func physics(delta: float) -> BossState:
	boss.velocity = Vector2.ZERO  # Стоим на месте
	return null

func exit() -> void:
	# Возвращаем анимацию idle при выходе
	boss.update_animation("idle")
