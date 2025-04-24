# SkillResource.gd
class_name SkillResource
extends Resource

enum SkillType { ACTIVE, PASSIVE }
enum Element { NONE, FIRE, WATER, AIR, EARTH }
enum KeyBinding { NONE, Q, E, R, T }

@export var name: String = ""
@export var type: SkillType = SkillType.ACTIVE
@export var level: int = 1
@export var max_level: int = 5
@export var upgrade_success_chance: float = 1.0
@export var element: Element = Element.NONE
@export var key_binding: KeyBinding = KeyBinding.NONE
@export_multiline var description: String = ""
@export var base_value: int = 10
@export var cooldown: float = 1.0
@export var duration: float = 0.0

func _init():
	pass

func execute(player: Player) -> bool:
	if type != SkillType.ACTIVE:
		#print("Skill '%s' is not ACTIVE, cannot execute" % name)
		return false
	
	# Применяем эффект стихии
	apply_elemental_effect(player)
	return true

func apply_passive(player: Player) -> void:
	if type != SkillType.PASSIVE:
		#print("Skill '%s' is not PASSIVE, cannot apply passive" % name)
		return
	
	# Применяем пассивный эффект стихии
	match element:
		Element.FIRE:
			EffectManager.apply_effect(player, DamageBoostEffect.new(base_value * level))
		Element.WATER:
			EffectManager.apply_effect(player, RegenerationEffect.new(base_value * level))
		Element.AIR:
			EffectManager.apply_effect(player, SpeedBoostEffect.new(base_value * level))
		Element.EARTH:
			EffectManager.apply_effect(player, HealthBoostEffect.new(base_value * level))

func remove_passive(player: Player) -> void:
	if type != SkillType.PASSIVE:
		#print("Skill '%s' is not PASSIVE, cannot remove passive" % name)
		return
	
	# Удаляем пассивный эффект
	match element:
		Element.FIRE:
			EffectManager.remove_effect(player, "DamageBoost")
		Element.WATER:
			EffectManager.remove_effect(player, "Regeneration")
		Element.AIR:
			EffectManager.remove_effect(player, "SpeedBoost")
		Element.EARTH:
			EffectManager.remove_effect(player, "HealthBoost")

func apply_elemental_effect(player: Player) -> void:
	if type == SkillType.ACTIVE:
		match element:
			Element.FIRE:
				var enemies = player.get_tree().get_nodes_in_group("enemies")
				for enemy in enemies:
					if enemy.global_position.distance_to(player.global_position) < 100:
						EffectManager.apply_effect(enemy, BurningEffect.new(base_value * level, 5.0))
			Element.WATER:
				var enemies = player.get_tree().get_nodes_in_group("enemies")
				for enemy in enemies:
					if enemy.global_position.distance_to(player.global_position) < 100:
						EffectManager.apply_effect(enemy, SlowEffect.new(base_value * level, 5.0))
			Element.AIR:
				var enemies = player.get_tree().get_nodes_in_group("enemies")
				for enemy in enemies:
					if enemy.global_position.distance_to(player.global_position) < 100:
						EffectManager.apply_effect(enemy, KnockbackEffect.new(base_value * level * 10, 0.1))
			Element.EARTH:
				EffectManager.apply_effect(player, ShieldEffect.new(base_value * level * 10, 5.0))

func get_description() -> String:
	var desc = description
	if element != Element.NONE:
		desc += " (Element: " + Element.keys()[element] + ")"
	if type == SkillType.ACTIVE and key_binding != KeyBinding.NONE:
		desc += " (Key: " + KeyBinding.keys()[key_binding] + ")"
	return desc + " [Level " + str(level) + "]"
