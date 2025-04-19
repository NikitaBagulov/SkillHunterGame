extends Node2D
class_name Projectile

# Настройки снаряда
@export var speed: float = 200.0  # Скорость движения
@export var lifetime: float = 5.0  # Время жизни снаряда (сек)
@export var damage: int = 1       # Урон, наносимый HurtBox

var direction: Vector2 = Vector2.ZERO  # Направление движения
var timer: float = 0.0

@onready var hurt_box: Area2D = $HurtBox  # Ссылка на HurtBox
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	timer = lifetime
	# Подключаем сигнал area_entered для HurtBox
	if hurt_box:
		hurt_box.connect("area_entered", _on_hurt_box_area_entered)

func _physics_process(delta: float) -> void:
	# Двигаем снаряд
	position += direction * speed * delta
	
	# Уменьшаем время жизни
	timer -= delta
	if timer <= 0.0:
		queue_free()

# Метод для установки направления
func set_direction(new_direction: Vector2) -> void:
	direction = new_direction
	# Поворачиваем спрайт, если нужно
	if has_node("Sprite2D"):
		var sprite = get_node("Sprite2D") as Sprite2D
		sprite.rotation = direction.angle()

# Обработка столкновения HurtBox с HitBox
func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.get_parent() is Player:  # Проверяем, принадлежит ли HitBox игроку
		# Наносим урон (предполагается, что у игрока есть метод take_damage)
		animation_player.play("explosion")
		await animation_player.animation_finished
		queue_free()  # Удаляем снаряд после анимации
