extends Node
class_name SkillManager

# Ссылка на данные инвентаря
@export var inventory_data: InventoryData

# Списки для хранения активных и пассивных навыков
var active_skills: Array[SkillResource] = []
var passive_skills: Array[SkillResource] = []

func _ready() -> void:
	# Проверяем, есть ли инвентарь, и подключаемся к его сигналу changed
	if inventory_data:
		inventory_data.connect("changed", Callable(self, "_on_inventory_changed"))
	# Выполняем начальное обновление навыков
	_update_skills()

# Обработчик изменения инвентаря
func _on_inventory_changed() -> void:
	_update_skills()

# Обновление списка навыков
func _update_skills() -> void:
	# Очищаем текущие списки навыков
	active_skills.clear()
	passive_skills.clear()
	
	# Проходим по всем слотам инвентаря
	for slot in inventory_data.slots:
		if slot and slot.item_data and slot.item_data.skill:
			var skill = slot.item_data.skill
			if skill.skill_type == SkillResource.SkillType.ACTIVE:
				active_skills.append(skill)
			else:
				passive_skills.append(skill)
	
	# Применяем все пассивные навыки
	_apply_passive_skills()

# Применение пассивных навыков
func _apply_passive_skills() -> void:
	for skill in passive_skills:
		skill.apply(get_parent()) # Предполагается, что get_parent() — это игрок

# Использование активного навыка
func use_active_skill(skill_index: int, target: Node = null) -> void:
	if skill_index < active_skills.size():
		var skill = active_skills[skill_index]
		skill.use(get_parent(), target) # Применяем активный навык
