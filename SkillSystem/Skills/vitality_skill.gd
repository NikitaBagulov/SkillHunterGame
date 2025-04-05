extends GDScript

func execute(player: Player, skill: SkillResource) -> bool:
	print("execute called for skill '%s' - not implemented for passive skill" % skill.name)
	return false

func apply_passive(player: Player, skill: SkillResource) -> void:
	print("Applying passive skill '%s' (Level: %d, Element: %s)" % [
		skill.name, 
		skill.level, 
		SkillResource.Element.keys()[skill.element]
	])
	var bonus = skill.base_value + (skill.level - 1) * 5
	print("Calculated bonus: %d (base_value: %d, level: %d)" % [bonus, skill.base_value, skill.level])
	
	match skill.element:
		SkillResource.Element.FIRE:
			print("Before FIRE apply - base_damage: %d" % PlayerManager.PLAYER_STATS.base_damage)
			PlayerManager.PLAYER_STATS.base_damage += bonus
			print("After FIRE apply - base_damage: %d" % PlayerManager.PLAYER_STATS.base_damage)
			PlayerManager.PLAYER_STATS.update_damage(player.get_attack_bonus())
			print("Updated damage with attack bonus: %d" % PlayerManager.PLAYER_STATS.total_damage)
		SkillResource.Element.WATER:
			print("WATER element not implemented yet")
			# Регенерация требует доработки Health
			pass
		SkillResource.Element.AIR:
			print("Before AIR apply - speed_bonus: %d" % PlayerManager.PLAYER_STATS.speed_bonus)
			PlayerManager.PLAYER_STATS.speed_bonus += bonus
			print("After AIR apply - speed_bonus: %d" % PlayerManager.PLAYER_STATS.speed_bonus)
		SkillResource.Element.EARTH:
			print("Before EARTH apply - max_hp: %d, hp: %d" % [
				PlayerManager.PLAYER_STATS.max_hp, 
				PlayerManager.PLAYER_STATS.hp
			])
			PlayerManager.PLAYER_STATS.max_hp += bonus
			print("After EARTH apply (max_hp increased) - max_hp: %d" % PlayerManager.PLAYER_STATS.max_hp)
			PlayerManager.PLAYER_STATS.heal(bonus)
			print("After EARTH heal - hp: %d, max_hp: %d" % [
				PlayerManager.PLAYER_STATS.hp, 
				PlayerManager.PLAYER_STATS.max_hp
			])

func remove_passive(player: Player, skill: SkillResource) -> void:
	print("Removing passive skill '%s' (Level: %d, Element: %s)" % [
		skill.name, 
		skill.level, 
		SkillResource.Element.keys()[skill.element]
	])
	var bonus = skill.base_value + (skill.level - 1) * 5
	print("Calculated bonus to remove: %d" % bonus)
	
	match skill.element:
		SkillResource.Element.FIRE:
			print("Before FIRE remove - base_damage: %d" % PlayerManager.PLAYER_STATS.base_damage)
			PlayerManager.PLAYER_STATS.base_damage -= bonus
			print("After FIRE remove - base_damage: %d" % PlayerManager.PLAYER_STATS.base_damage)
			PlayerManager.PLAYER_STATS.update_damage(player.get_attack_bonus())
			print("Updated damage with attack bonus: %d" % PlayerManager.PLAYER_STATS.total_damage)
		SkillResource.Element.WATER:
			print("WATER element not implemented yet")
			pass
		SkillResource.Element.AIR:
			print("Before AIR remove - speed_bonus: %d" % PlayerManager.PLAYER_STATS.speed_bonus)
			PlayerManager.PLAYER_STATS.speed_bonus -= bonus
			print("After AIR remove - speed_bonus: %d" % PlayerManager.PLAYER_STATS.speed_bonus)
		SkillResource.Element.EARTH:
			print("Before EARTH remove - max_hp: %d, hp: %d" % [
				player.health.stats.max_hp, 
				player.health.stats.hp
			])
			player.health.stats.max_hp -= bonus
			print("After EARTH remove (max_hp decreased) - max_hp: %d" % player.health.stats.max_hp)
			player.health.stats.hp = min(player.health.stats.hp, player.health.stats.max_hp)
			print("After EARTH hp adjustment - hp: %d, max_hp: %d" % [
				player.health.stats.hp, 
				player.health.stats.max_hp
			])
