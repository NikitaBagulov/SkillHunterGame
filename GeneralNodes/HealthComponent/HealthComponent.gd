# Health.gd
extends Node
class_name Health

var player: Player 
var hit_box: HitBox 

@export var stats: Stats  # Создаём экземпляр Stats

func _ready() -> void:
	if PlayerManager.get_player():
		initialize()
	else:
		# Ждём, пока игрок появится
		await PlayerManager.player_assigned
		initialize()

func initialize() -> void:
	player = PlayerManager.get_player()
	hit_box = player.get_node("HitBox")
	stats.hp = stats.max_hp
	Hud.update_max_hp(stats.max_hp)
	Hud.update_hp(stats.hp, stats.max_hp)
	stats.take_damage(0)  # Инициализация UI

func update_hp(delta: int) -> void:
	stats.hp = clampi(stats.hp + delta, 0, stats.max_hp)
	Hud.update_hp(stats.hp, stats.max_hp)

func take_damage(hurt_box: HurtBox) -> void:
	if player.invulnerable:
		return
	stats.take_damage(hurt_box.damage)
	if stats.hp > 0:
		player.player_damaged.emit(hurt_box)
	else:
		player.player_damaged.emit(hurt_box)
		stats.hp = stats.max_hp  # Восстановление при смерти

func heal(amount: int) -> void:
	stats.heal(amount)

func make_invulnerable(duration: float = 1.0) -> void:
	player.invulnerable = true
	hit_box.monitoring = false
	await get_tree().create_timer(duration).timeout
	player.invulnerable = false
	hit_box.monitoring = true
