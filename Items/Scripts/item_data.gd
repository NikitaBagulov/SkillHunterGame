class_name ItemData extends Resource

@export var name: String = ""
@export_multiline var description: String = ""
@export var texture: Texture2D
@export var skill: SkillResource

@export_category("Item Use Effect")
@export var effects: Array[ItemEffect]

func use() -> bool:
	if effects.size() == 0:
		return false
	
	for effect in effects:
		effect.use()
	return true
