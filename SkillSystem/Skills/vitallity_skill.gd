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
	
	match element:
		Element.FIRE:
			stats.update_damage(bonus)
			#stats.update_damage(player.get_attack_bonus())
		Element.WATER:
			#print("WATER: Not implemented")
			pass
		Element.AIR:
			stats.speed_bonus += bonus
		Element.EARTH:
			stats.update_health(bonus)
	#PlayerManager.update_equipment_damage()
	PlayerManager.update_health() 
	
func remove_passive(player: Player) -> void:
	var bonus = base_value + (level - 1) * 5
	var stats = PlayerManager.PLAYER_STATS
	match element:
		Element.FIRE:
			stats.update_damage(bonus)
			#stats.update_damage(player.get_attack_bonus())
		Element.WATER:
			pass
		Element.AIR:
			stats.speed_bonus -= bonus
		Element.EARTH:
			stats.update_health(0)
	#PlayerManager.update_equipment_damage()
	PlayerManager.update_health() 
