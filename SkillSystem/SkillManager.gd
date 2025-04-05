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
		return false
	if not is_skill_equipped(skill):
		return false

	var success = skill.execute(player)
	if success:
		active_skill_cooldowns[skill] = skill.cooldown
	return success

func update_passive_skills() -> void:
	var equipped_items = get_equipped_items()
	for item in equipped_items:
		if item.skill and item.skill.type == SkillResource.SkillType.PASSIVE:
			item.skill.remove_passive(player)
	for item in equipped_items:
		if item.skill and item.skill.type == SkillResource.SkillType.PASSIVE:
			item.skill.apply_passive(player)
	
	if player.health:
		player.health.update_hp(0)
	var equipped_weapon = PlayerManager.INVENTORY_DATA.get_equipped_weapon()
	if equipped_weapon:
		PlayerManager.PLAYER_STATS.update_damage(equipped_weapon.get_attack_bonus())
	else:
		PlayerManager.PLAYER_STATS.update_damage(0)

func get_equipped_items() -> Array[EquipableItemData]:
	var items: Array[EquipableItemData] = []
	var weapon = PlayerManager.INVENTORY_DATA.get_equipped_weapon()
	if weapon:
		items.append(weapon)
	return items

func is_skill_equipped(skill: SkillResource) -> bool:
	var equipped_items = get_equipped_items()
	for item in equipped_items:
		if item.skill == skill:
			return true
	return false
