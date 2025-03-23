extends GDScript

func execute(player: Player, skill: SkillResource) -> bool:
	var damage = skill.base_value + (skill.level - 1) * 5  # Увеличение урона с уровнем
	player.attack_hurt_box.damage = damage
	player.animation_player.play("attack_" + player.animation_direction())
	return true

func apply_passive(player: Player, skill: SkillResource) -> void:
	pass  # Не используется для активного навыка
