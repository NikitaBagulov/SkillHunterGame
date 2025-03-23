extends GDScript

func execute(player: Player, skill: SkillResource) -> bool:
	return false

func apply_passive(player: Player, skill: SkillResource) -> void:
	var bonus = skill.base_value + (skill.level - 1) * 5
	match skill.element:
		SkillResource.Element.FIRE:
			PlayerManager.PLAYER_STATS.base_damage += bonus
			PlayerManager.PLAYER_STATS.update_damage(player.get_attack_bonus())
		SkillResource.Element.WATER:
			# Регенерация требует доработки Health
			pass
		SkillResource.Element.AIR:
			PlayerManager.PLAYER_STATS.speed_bonus += bonus
		SkillResource.Element.EARTH:
			print(bonus, "bonus, ", PlayerManager.PLAYER_STATS.max_hp)
			PlayerManager.PLAYER_STATS.max_hp += bonus
			print(bonus, "bonus, ", PlayerManager.PLAYER_STATS.max_hp)
			PlayerManager.PLAYER_STATS.heal(bonus)

func remove_passive(player: Player, skill: SkillResource) -> void:
	var bonus = skill.base_value + (skill.level - 1) * 5
	match skill.element:
		SkillResource.Element.FIRE:
			PlayerManager.PLAYER_STATS.base_damage -= bonus
			PlayerManager.PLAYER_STATS.update_damage(player.get_attack_bonus())
		SkillResource.Element.WATER:
			pass
		SkillResource.Element.AIR:
			PlayerManager.PLAYER_STATS.speed_bonus -= bonus
		SkillResource.Element.EARTH:
			player.health.stats.max_hp -= bonus
			player.health.stats.hp = min(player.health.stats.hp, player.health.stats.max_hp)
