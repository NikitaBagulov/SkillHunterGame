# Health.gd
class_name Health
extends Node

@onready var player: Player = get_parent()
@onready var hit_box: HitBox = player.get_node("HitBox")

@export var max_hp: int = 6
var hp: int = max_hp

func _ready() -> void:
	update_hp(0)  # Инициализация HUD
	pass

func take_damage(hurt_box: HurtBox) -> void:
	if player.invulnerable:
		return
	update_hp(-hurt_box.damage)
	if hp > 0:
		player.player_damaged.emit(hurt_box)
	else:
		player.player_damaged.emit(hurt_box)
		update_hp(99)  # Восстановление HP при смерти

func heal(amount: int) -> void:
	update_hp(amount)

func update_hp(delta: int) -> void:
	hp = clampi(hp + delta, 0, max_hp)
	Hud.update_hp(hp, max_hp)

func make_invulnerable(duration: float = 1.0) -> void:
	player.invulnerable = true
	hit_box.monitoring = false
	await get_tree().create_timer(duration).timeout
	player.invulnerable = false
	hit_box.monitoring = true
