class_name SkillManager
extends Node

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
	update_passive_skills()
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
					# Вызываем асинхронный метод use_skill
					use_skill(item.skill)

# Делаем метод асинхронным с помощью async
func use_skill(skill: SkillResource) -> bool:
	if skill.type != SkillResource.SkillType.ACTIVE:
		print("Skill '%s' is not ACTIVE" % skill.name)
		return false
	if active_skill_cooldowns.has(skill):
		print("Skill '%s' is on cooldown: %.1f" % [skill.name, active_skill_cooldowns[skill]])
		return false
	if not is_skill_equipped(skill):
		print("Skill '%s' is not equipped" % skill.name)
		return false

	# Добавляем await для асинхронного вызова execute
	var success = await skill.execute(player)
	if success:
		active_skill_cooldowns[skill] = skill.cooldown
		print("Skill '%s' executed successfully, cooldown set to %.1f" % [skill.name, skill.cooldown])
	else:
		print("Skill '%s' execution failed" % skill.name)
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
	
	# Получаем инвентарь из Repository
	var inventory_data = Repository.instance.get_data("inventory", "data", null)
	var equipped_weapon = inventory_data.get_equipped_weapon() if inventory_data else null
	if equipped_weapon:
		PlayerManager.PLAYER_STATS.update_damage(inventory_data.get_equipped_weapon_damage_bonus())
	#else:
		#PlayerManager.PLAYER_STATS.update_damage(0)

func get_equipped_items() -> Array[EquipableItemData]:
	var items: Array[EquipableItemData] = []
	# Получаем инвентарь из Repository
	var inventory_data = Repository.instance.get_data("inventory", "data", null)
	var weapon = inventory_data.get_equipped_weapon() if inventory_data else null
	if weapon:
		items.append(weapon)
	return items

func is_skill_equipped(skill: SkillResource) -> bool:
	var equipped_items = get_equipped_items()
	for item in equipped_items:
		if item.skill == skill:
			return true
	return false
