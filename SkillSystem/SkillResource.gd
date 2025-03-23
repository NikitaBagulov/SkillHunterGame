class_name SkillResource extends Resource

enum SkillType { ACTIVE, PASSIVE }
enum Element { NONE, FIRE, WATER, AIR, EARTH }
enum KeyBinding { NONE, Q, E, R, T }

@export var name: String = ""
@export var type: SkillType = SkillType.ACTIVE
@export var level: int = 1
@export var element: Element = Element.NONE
@export var key_binding: KeyBinding = KeyBinding.NONE
@export_multiline var description: String = ""
@export var base_value: int = 10
@export var cooldown: float = 1.0
@export var duration: float = 0.0

@export var custom_logic: GDScript
var logic_instance = null

func _init():
	if custom_logic:
		logic_instance = custom_logic.new()
		if logic_instance:
			print("Skill '%s' initialized with logic: %s" % [name, custom_logic.resource_path])
		else:
			print("Failed to initialize logic for skill '%s'" % name)
	else:
		print("No custom logic assigned to skill '%s'" % name)

func execute(player: Player) -> bool:
	if not logic_instance:
		print("No logic instance for skill '%s' (ACTIVE)" % name)
		return false
	if type != SkillType.ACTIVE:
		print("Skill '%s' is not ACTIVE" % name)
		return false
	var success = logic_instance.execute(player, self)
	if success:
		apply_elemental_effect(player)
		print("Skill '%s' executed successfully" % name)
	else:
		print("Skill '%s' execution failed" % name)
	return success

func apply_passive(player: Player) -> void:
	if type != SkillType.PASSIVE:
		print("Skill '%s' is not PASSIVE" % name)
		return
	if not logic_instance:
		print("No logic instance for skill '%s' (PASSIVE)" % name)
		return
	logic_instance.apply_passive(player, self)
	print("Skill '%s' passive applied" % name)

func remove_passive(player: Player) -> void:
	if type != SkillType.PASSIVE:
		return
	if not logic_instance:
		print("No logic instance for skill '%s' (PASSIVE)" % name)
		return
	logic_instance.remove_passive(player, self)
	print("Skill '%s' passive removed" % name)

func apply_elemental_effect(player: Player) -> void:
	match element:
		Element.FIRE:
			player.effect_animation_player.play("fire_effect")
		Element.WATER:
			player.effect_animation_player.play("water_effect")
		Element.AIR:
			player.effect_animation_player.play("air_effect")
		Element.EARTH:
			player.effect_animation_player.play("earth_effect")
