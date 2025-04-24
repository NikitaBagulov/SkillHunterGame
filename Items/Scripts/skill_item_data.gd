class_name SkillItemData extends ItemData

enum SkillItemType { SKILL, ELEMENT }
@export var skill_item_type: SkillItemType = SkillItemType.SKILL

# Для элементов
@export var element: SkillResource.Element = SkillResource.Element.NONE

func _init():
	if skill_item_type == SkillItemType.ELEMENT and element == SkillResource.Element.NONE:
		pass
		#print("Warning: SkillItemData created as ELEMENT with no element specified!")
