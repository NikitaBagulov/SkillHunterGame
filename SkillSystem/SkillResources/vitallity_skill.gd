class_name VitalitySkill
extends SkillResource

var stats = PlayerManager.PLAYER_STATS

func _init():
	name = "Vitality"
	type = SkillType.PASSIVE
	base_value = 10
	element = Element.EARTH

func apply_passive(player: Player) -> void:
	var bonus = base_value + (level - 1) * 5
	print("Applying '%s' - Bonus: %d (Level: %d)" % [name, bonus, level])
	
	match element:
		Element.FIRE:
			stats.base_damage += bonus
			#stats.update_damage(player.get_attack_bonus())
			print("FIRE: Increased base_damage by %d" % bonus)
		Element.WATER:
			print("WATER: Not implemented")
		Element.AIR:
			stats.speed_bonus += bonus
			print("AIR: Increased speed_bonus by %d" % bonus)
		Element.EARTH:
			stats.max_hp += bonus
			stats.heal(bonus)
			print("EARTH: Increased max_hp and hp by %d" % bonus)

func remove_passive(player: Player) -> void:
	var bonus = base_value + (level - 1) * 5
	print("Removing '%s' - Bonus: %d (Level: %d)" % [name, bonus, level])
	var stats = PlayerManager.PLAYER_STATS
	match element:
		Element.FIRE:
			stats.base_damage -= bonus
			#stats.update_damage(player.get_attack_bonus())
			print("FIRE: Decreased base_damage by %d" % bonus)
		Element.WATER:
			print("WATER: Not implemented")
		Element.AIR:
			stats.speed_bonus -= bonus
			print("AIR: Decreased speed_bonus by %d" % bonus)
		Element.EARTH:
			stats.max_hp -= bonus
			stats.hp = min(stats.hp, stats.max_hp)
			print("EARTH: Decreased max_hp by %d" % bonus)
