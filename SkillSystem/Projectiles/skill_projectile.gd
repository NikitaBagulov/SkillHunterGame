extends Node2D
class_name SkillProjectile

# Настройки снаряда
@export var speed: float = 200.0  # Скорость движения
@export var lifetime: float = 5.0  # Время жизни снаряда (сек)
@export var damage: int = 5       # Урон, наносимый HurtBox
@export var element: SkillResource.Element = SkillResource.Element.NONE  # Элемент снаряда
@export var search_radius: float = 300.0  # Радиус поиска врагов

var direction: Vector2 = Vector2.ZERO  # Направление движения
var timer: float = 0.0
var target: Node = null  # Цель для самонаведения
var projectile_owner: Node = null  # Игрок, выпустивший снаряд

@onready var hurt_box: Area2D = $HurtBox  # Ссылка на HurtBox
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	timer = lifetime
	# Подключаем сигнал area_entered для HurtBox
	if hurt_box:
		hurt_box.damage = damage
		hurt_box.connect("area_entered", _on_hurt_box_area_entered)
	# Находим ближайшего врага
	find_target()

func _physics_process(delta: float) -> void:
	# Обновляем цель, если текущая недействительна
	if not is_instance_valid(target):
		find_target()
	
	# Двигаем снаряд
	if is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	elif direction == Vector2.ZERO:
		direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	position += direction * speed * delta
	
	# Поворачиваем спрайт, если есть
	if has_node("Sprite2D"):
		var sprite = get_node("Sprite2D") as Sprite2D
		sprite.rotation = direction.angle()
	
	# Уменьшаем время жизни
	timer -= delta
	if timer <= 0.0:
		queue_free()
		
func find_target() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	target = null
	if enemies.size() > 0:
		var closest = enemies[0]
		var closest_target_point = closest.global_position + Vector2(0, -20)  # Смещение на 20 пикселей вверх
		var min_distance = global_position.distance_to(closest_target_point)
		for enemy in enemies:
			var target_point = enemy.global_position# Смещение для каждого врага
			var distance = global_position.distance_to(target_point)
			if distance < min_distance and distance <= search_radius:
				closest = enemy
				closest_target_point = target_point
				min_distance = distance
		target = closest

# Обработка столкновения HurtBox с HitBox
func _on_hurt_box_area_entered(area: Area2D) -> void:
	print("Swarm area: ", area)
	if area.get_parent() is Enemy or area.get_parent() is Boss:
		var body = area.get_parent()
		match element:
			SkillResource.Element.FIRE:
				EffectManager.apply_effect(body, BurningEffect.new(damage * 0.5, 5.0))
			SkillResource.Element.WATER:
				EffectManager.apply_effect(body, SlowEffect.new(30.0, 5.0))
			SkillResource.Element.AIR:
				EffectManager.apply_effect(body, KnockbackEffect.new(damage * 5, 0.1))
			SkillResource.Element.EARTH:
				if is_instance_valid(projectile_owner):
					EffectManager.apply_effect(projectile_owner, ShieldEffect.new(damage * 2, 5.0))
		print("Projectile hit %s, dealt %s damage" % [body.name, damage])
		animation_player.play("explosion")
		await animation_player.animation_finished
		queue_free()  # Удаляем снаряд после анимации
