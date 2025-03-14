# RegenerationSkill.gd
class_name RegenerationSkill
extends SkillResource

func _init() -> void:
	skill_type = SkillType.PASSIVE
	element = Element.WATER
	name = "Регенерация"
	description = "Постепенно восстанавливает здоровье"

func apply(caster: Node) -> void:
	if caster.has_method("heal"):
		caster.heal(1)  # Восстанавливает 1 HP (например, каждую секунду)
	print("Регенерация применена к ", caster)
