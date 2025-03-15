# EnemyStateDestroy.gd
extends EnemyState
class_name EnemyStateDestroy

const PICKUP = preload("res://GeneralNodes/Item_pickup/ItemPickup.tscn")

@export var animation_name: String = "destroy"
@export var knockback_speed: float = 200.0
@export var decelerate_speed: float = 10.0

@export_category("ItemDrops")
@export var drops: Array[DropData]

var _damage_position: Vector2
var _direction: Vector2

func init() -> void:
	enemy.enemy_destroyed.connect(_on_enemy_destroyed)

func enter() -> void:
	enemy.invulnerable = true
	_direction = enemy.global_position.direction_to(_damage_position)
	
	enemy.set_direction(_direction)
	enemy.velocity = _direction * -knockback_speed
	
	enemy.update_animation(animation_name)
	enemy.animation_player.animation_finished.connect(_on_animation_finished)
	
	disable_hurt_box()
	drop_items()

func exit() -> void:
	pass

func process(_delta: float) -> EnemyState:
	enemy.velocity -= enemy.velocity * decelerate_speed * _delta
	return null

func physics(_delta: float) -> EnemyState:
	return null

func _on_enemy_destroyed(hurt_box: HurtBox) -> void:
	_damage_position = hurt_box.global_position
	state_machine.change_state(self)

func _on_animation_finished(_animation: String) -> void:
	# Начисляем опыт перед удалением врага
	var player = PlayerManager.get_player()
	if player and player.experience_manager:
		player.experience_manager.gain_experience(enemy.experience_drop)
		print("Начислено опыта:", enemy.experience_drop)
	enemy.queue_free()  # Удаляем врага после начисления опыта

func disable_hurt_box() -> void:
	var hurt_box: HurtBox = enemy.get_node_or_null("HurtBox")
	if hurt_box:
		hurt_box.monitoring = false

func drop_items() -> void:
	if drops.size() == 0:
		return
	for i in drops.size():
		if drops[i] == null or drops[i].item == null:
			continue
		var drop_count: int = drops[i].get_drop_count()
		for j in drop_count:
			var drop: ItemPickup = PICKUP.instantiate() as ItemPickup
			drop.item_data = drops[i].item
			enemy.get_parent().call_deferred("add_child", drop)
			drop.global_position = enemy.global_position + Vector2(randf()*16, randf()*16)
