class_name SkillManager extends Node

@export var player: Player
var active_skill_cooldowns: Dictionary = {}

const KEY_MAP = {
	SkillResource.KeyBinding.Q: KEY_Q,
	SkillResource.KeyBinding.E: KEY_E,
	SkillResource.KeyBinding.R: KEY_R,
	SkillResource.KeyBinding.T: KEY_T
}

func _ready() -> void:
	if not player:
		player = get_parent() as Player
	assert(player != null, "SkillManager requires a Player reference")
	update_passive_skills()

func _process(delta: float) -> void:
	for skill in active_skill_cooldowns.keys():
		active_skill_cooldowns[skill] -= delta
		if active_skill_cooldowns[skill] <= 0:
			active_skill_cooldowns.erase(skill)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var equipped_items = get_equipped_items()
		for item in equipped_items:
			if item.skill and item.skill.type == SkillResource.SkillType.ACTIVE:
				var key = KEY_MAP.get(item.skill.key_binding, -1)
				if event.keycode == key:
					use_skill(item.skill)

func use_skill(skill: SkillResource) -> bool:
	if skill.type != SkillResource.SkillType.ACTIVE:
		return false
	if active_skill_cooldowns.has(skill):
		print("Skill '%s' on cooldown (remaining: %.2f)" % [skill.name, active_skill_cooldowns[skill]])
		return false
	if not is_skill_equipped(skill):
		print("Skill '%s' not equipped" % skill.name)
		return false

	var success = skill.execute(player)
	if success:
		active_skill_cooldowns[skill] = skill.cooldown
	return success

func update_passive_skills() -> void:
	reset_stats()
	var equipped_items = get_equipped_items()
	for item in equipped_items:
		if item.skill and item.skill.type == SkillResource.SkillType.PASSIVE:
			item.skill.apply_passive(player)
	if player.health:
		player.health.update_hp(0)
	var equipped_weapon = PlayerManager.INVENTORY_DATA.get_equipped_weapon()
	if equipped_weapon:
		PlayerManager.PLAYER_STATS.update_damage(equipped_weapon.get_attack_bonus())

func reset_stats() -> void:
	var base_stats = PlayerManager.PLAYER_STATS
	base_stats.speed_bonus = 0
	# Не сбрасываем base_damage и max_hp полностью, чтобы сохранить их базовые значения

func get_equipped_items() -> Array[EquipableItemData]:
	var items: Array[EquipableItemData] = []
	var weapon = PlayerManager.INVENTORY_DATA.get_equipped_weapon()
	if weapon:
		items.append(weapon)
	# Добавьте другие слоты, если они есть
	return items

func is_skill_equipped(skill: SkillResource) -> bool:
	var equipped_items = get_equipped_items()
	for item in equipped_items:
		if item.skill == skill:
			return true
	return false

func upgrade_skill(skill1: SkillResource, skill2: SkillResource) -> SkillResource:
	if skill1.name != skill2.name or skill1.level != skill2.level:
		return null
	var new_skill = skill1.duplicate()
	new_skill.level += 1
	update_passive_skills()
	return new_skill

func imbue_element(skill: SkillResource, element: SkillResource.Element) -> void:
	skill.element = element
	update_passive_skills()

# Метод для проверки текущих навыков
func check_skills_status() -> void:
	print("=== Skills Status ===")
	var equipped_items = get_equipped_items()
	if equipped_items.is_empty():
		print("No equipped items with skills")
	else:
		for item in equipped_items:
			if item.skill:
				var skill = item.skill
				print("Skill: %s (Type: %s, Level: %d, Element: %s)" % [
					skill.name,
					SkillResource.SkillType.keys()[skill.type],
					skill.level,
					SkillResource.Element.keys()[skill.element]
				])
				if skill.type == SkillResource.SkillType.ACTIVE:
					var cooldown = active_skill_cooldowns.get(skill, 0.0)
					print(" - Active, Key: %s, Cooldown: %.2f" % [
						SkillResource.KeyBinding.keys()[skill.key_binding],
						cooldown
					])
				else:
					print(" - Passive, Applied")
