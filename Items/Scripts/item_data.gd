class_name ItemData extends Resource

@export var item_id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var texture: Texture2D
@export var skill: SkillResource
@export var cost: int = 0  # Добавляем стоимость предмета

@export_category("Item Use Effect")
@export var effects: Array[ItemEffect]

func use() -> bool:
	if effects.size() == 0:
		#print("ItemData '%s' has no effects to apply" % name)
		return false
	
	var success = false
	for effect in effects:
		effect.use()
		success = true
	return success
