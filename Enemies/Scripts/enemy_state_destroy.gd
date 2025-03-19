extends EnemyState
class_name EnemyStateDestroy

# --- Константы ---
## Сцена предмета для дропа
const PICKUP = preload("res://GeneralNodes/Item_pickup/ItemPickup.tscn")

# --- Настройки ---
## Имя анимации уничтожения
@export var animation_name: String = "destroy"
## Скорость отбрасывания при уничтожении
@export var knockback_speed: float = 200.0
## Скорость замедления после отбрасывания
@export var decelerate_speed: float = 10.0

# --- Настройки дропа ---
@export_category("ItemDrops")
## Список возможных предметов для дропа
@export var drops: Array[DropData] = []

# --- Переменные ---
## Позиция источника урона
var _damage_position: Vector2
## Направление отбрасывания
var _direction: Vector2

# --- Инициализация ---
func init() -> void:
	enemy.enemy_destroyed.connect(_on_enemy_destroyed)

# --- Управление состоянием ---
func enter() -> void:
	enemy.invulnerable = true
	_direction = enemy.global_position.direction_to(_damage_position)
	
	enemy.set_direction(_direction)
	enemy.velocity = _direction * -knockback_speed
	enemy.update_animation(animation_name)
	
	enemy.animation_player.animation_finished.connect(_on_animation_finished)
	disable_hurt_box()
	_drop_items()

func process(delta: float) -> EnemyState:
	enemy.velocity -= enemy.velocity * decelerate_speed * delta
	return null

# --- Обработчики событий ---
## Реакция на уничтожение врага
func _on_enemy_destroyed(hurt_box: HurtBox) -> void:
	_damage_position = hurt_box.global_position
	state_machine.change_state(self)

## Завершение анимации и удаление врага
func _on_animation_finished(_animation: String) -> void:
	var player = PlayerManager.get_player()
	if player and player.experience_manager:
		player.experience_manager.gain_experience(enemy.experience_drop)
		print("Experience gained: ", enemy.experience_drop)
	enemy.queue_free()

# --- Вспомогательные методы ---
## Отключает зону урона врага
func disable_hurt_box() -> void:
	var hurt_box = enemy.get_node_or_null("HurtBox")
	if hurt_box:
		hurt_box.monitoring = false

## Создает предметы дропа
func _drop_items() -> void:
	if drops.is_empty():
		return
	
	for drop_data in drops:
		if not drop_data or not drop_data.item:
			continue
		var drop_count = drop_data.get_drop_count()
		for _i in drop_count:
			var pickup = PICKUP.instantiate() as ItemPickup
			pickup.item_data = drop_data.item
			enemy.get_parent().call_deferred("add_child", pickup)
			pickup.global_position = enemy.global_position + Vector2(randf() * 16, randf() * 16)
