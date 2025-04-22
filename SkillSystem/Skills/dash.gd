class_name DashSkill
extends SkillResource

var stats = PlayerManager.PLAYER_STATS

func _init():
	name = "Dash"
	type = SkillType.ACTIVE
	level = 1
	key_binding = KeyBinding.Q  # Привязываем к клавише Q
	description = "Быстро перемещает игрока в направлении движения."
	base_value = 50  # Базовая дистанция рывка (в пикселях)
	cooldown = 2.0    # Перезарядка 2 секунды
	duration = 0.2    # Длительность рывка (в секундах)

# Переопределяем метод execute для активного навыка
func execute(player: Player) -> bool:
	if type != SkillType.ACTIVE:
		print("Skill '%s' is not ACTIVE, cannot execute" % name)
		return false
	
	# Проверяем, есть ли направление движения
	if player.direction == Vector2.ZERO:
		print("No direction for Dash!")
		return false
	
	# Вычисляем скорость рывка: дистанция / длительность
	var dash_distance = base_value + (level - 1) * 50  # Увеличение дистанции с уровнем
	var dash_speed = dash_distance / duration
	print("Executing '%s' - Distance: %d, Speed: %d" % [name, dash_distance, dash_speed])
	
	# Сохраняем текущую скорость и устанавливаем скорость рывка
	var original_speed = stats.move_speed
	stats.move_speed = dash_speed
	
	# Применяем визуальный эффект стихии AIR
	apply_elemental_effect(player)
	
	# Запускаем таймер длительности рывка
	await player.get_tree().create_timer(duration).timeout
	
	# Восстанавливаем исходную скорость после рывка
	stats.move_speed = original_speed
	print("Dash completed, speed restored to: ", stats.move_speed)
	
	return true

# Переопределяем apply_passive (не используется, но оставим заглушку)
func apply_passive(player: Player) -> void:
	if type != SkillType.PASSIVE:
		print("Skill '%s' is not PASSIVE, cannot apply passive" % name)
		return
	print("'%s' is an active skill, apply_passive not applicable" % name)

# Переопределяем remove_passive (не используется, но оставим заглушку)
func remove_passive(player: Player) -> void:
	if type != SkillType.PASSIVE:
		print("Skill '%s' is not PASSIVE, cannot remove passive" % name)
		return
	print("'%s' is an active skill, remove_passive not applicable" % name)
