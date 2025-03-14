class_name SkillResource
extends Resource

# Типы навыков
enum SkillType { ACTIVE, PASSIVE }

# Типы элементов (если используются)
enum Element { NONE, FIRE, WATER, WIND, EARTH }

@export var skill_type: SkillType
@export var element: Element
@export var name: String = ""
@export_multiline var description: String = ""
# Метод для активных навыков (переопределяется в дочерних классах)
func use(caster: Node, target: Node = null) -> void:
	if skill_type == SkillType.ACTIVE:
		print("Базовая реализация активного навыка")

# Метод для пассивных навыков (переопределяется в дочерних классах)
func apply(caster: Node) -> void:
	if skill_type == SkillType.PASSIVE:
		print("Базовая реализация пассивного навыка")
