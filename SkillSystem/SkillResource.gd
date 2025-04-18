class_name SkillResource extends Resource

enum SkillType { ACTIVE, PASSIVE }
enum Element { NONE, FIRE, WATER, AIR, EARTH }
enum KeyBinding { NONE, Q, E, R, T }

@export var name: String = ""
@export var type: SkillType = SkillType.ACTIVE
@export var level: int = 1
@export var max_level: int = 5  # Максимальный уровень по умолчанию
@export var upgrade_success_chance: float = 1.0  # 1.0 = 100% по умолчанию
@export var element: Element = Element.NONE
@export var key_binding: KeyBinding = KeyBinding.NONE
@export_multiline var description: String = ""
@export var base_value: int = 10  # Базовое значение (урон/бонус)
@export var cooldown: float = 1.0  # Перезарядка для активных
@export var duration: float = 0.0  # Длительность эффекта

func _init():
	print("Skill '%s' initialized (Type: %s, Element: %s)" % [
		name,
		SkillType.keys()[type],
		Element.keys()[element]
	])

# Виртуальный метод для активных навыков
func execute(player: Player) -> bool:
	if type != SkillType.ACTIVE:
		print("Skill '%s' is not ACTIVE, cannot execute" % name)
		return false
	print("Default execute called for '%s' - override this method in inherited script" % name)
	return false

# Виртуальный метод для применения пассивного эффекта
func apply_passive(player: Player) -> void:
	if type != SkillType.PASSIVE:
		print("Skill '%s' is not PASSIVE, cannot apply passive" % name)
		return
	print("Default apply_passive called for '%s' - override this method in inherited script" % name)

# Виртуальный метод для снятия пассивного эффекта
func remove_passive(player: Player) -> void:
	if type != SkillType.PASSIVE:
		print("Skill '%s' is not PASSIVE, cannot remove passive" % name)
		return
	print("Default remove_passive called for '%s' - override this method in inherited script" % name)

# Применение эффекта стихии
func apply_elemental_effect(player: Player) -> void:
	match element:
		Element.FIRE:
			player.effect_animation_player.play("fire_effect")
			print("Applied FIRE effect for '%s'" % name)
		Element.WATER:
			player.effect_animation_player.play("water_effect")
			print("Applied WATER effect for '%s'" % name)
		Element.AIR:
			player.effect_animation_player.play("air_effect")
			print("Applied AIR effect for '%s'" % name)
		Element.EARTH:
			player.effect_animation_player.play("earth_effect")
			print("Applied EARTH effect for '%s'" % name)

func get_description() -> String:
	var desc = description
	if element != Element.NONE:
		desc += " (Element: " + Element.keys()[element] + ")"
	if type == SkillType.ACTIVE and key_binding != KeyBinding.NONE:
		desc += " (Key: " + KeyBinding.keys()[key_binding] + ")"
	return desc + " [Level " + str(level) + "]"
