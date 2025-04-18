class_name SkillForgeUI extends Control

signal ready_completed

@onready var input_slot_1: InventorySlotUI = $Panel/MainContainer/InputContainer/InputSlot1
@onready var input_slot_2: InventorySlotUI = $Panel/MainContainer/InputContainer/InputSlot2
@onready var output_slot: InventorySlotUI = $Panel/MainContainer/InputContainer/OutputSlot
@onready var forge_button: Button = $Panel/MainContainer/ButtonContainer/ForgeButton

var inventory_data: InventoryData = PlayerManager.INVENTORY_DATA

func _ready() -> void:
	forge_button.pressed.connect(_on_forge_button_pressed)
	# Устанавливаем ограничения на типы предметов для слотов
	input_slot_1.slot_type = -1  # Будем проверять вручную
	input_slot_2.slot_type = -1  # Будем проверять вручную
	clear_slots()
	update_layout()
	# Подключаем сигнал изменения инвентаря для отслеживания изменений в слотах
	inventory_data.data_changed.connect(_on_inventory_changed)
	# Изначально обновляем состояние кнопки
	update_forge_button_state()
	ready_completed.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		update_layout()

func update_layout() -> void:
	var screen_size = get_viewport_rect().size
	#var min_slot_size = Vector2(64, 64)
	#input_slot_1.custom_minimum_size = min_slot_size
	#input_slot_2.custom_minimum_size = min_slot_size
	#output_slot.custom_minimum_size = min_slot_size
	#skill_output_slot.custom_minimum_size = min_slot_size
	#forge_button.custom_minimum_size = Vector2(100, 40).clamp(Vector2.ZERO, screen_size * 0.2)
	#output_label.size.x = screen_size.x * 0.8

func clear_slots() -> void:
	input_slot_1.set_slot_data(null)
	input_slot_2.set_slot_data(null)
	output_slot.set_slot_data(null)
	update_forge_button_state()

# Метод для проверки состояния слотов и обновления кнопки
func update_forge_button_state() -> void:
	var slot_1_data = input_slot_1.slot_data
	var slot_2_data = input_slot_2.slot_data
	if slot_1_data == null or slot_2_data == null:
		forge_button.disabled = true
		return
	
	var forge_result = forge_items(slot_1_data, slot_2_data)
	forge_button.disabled = not forge_result.success

# Вызывается при изменении инвентаря (например, после перетаскивания)
func _on_inventory_changed() -> void:
	# Проверяем, что слоты UI соответствуют данным инвентаря
	if input_slot_1.slot_data and inventory_data.slots.find(input_slot_1.slot_data) == -1:
		input_slot_1.set_slot_data(null)
	if input_slot_2.slot_data and inventory_data.slots.find(input_slot_2.slot_data) == -1:
		input_slot_2.set_slot_data(null)
	update_forge_button_state()

func _on_forge_button_pressed() -> void:
	var slot_1_data = input_slot_1.slot_data
	var slot_2_data = input_slot_2.slot_data
	
	var result = forge_items(slot_1_data, slot_2_data)
	if result.success:
		var new_slot_data = SlotData.new()
		new_slot_data.item_data = result.output_item
		new_slot_data.quantity = 1
		
		# Устанавливаем результат в output_slot
		set_output_slot_data(new_slot_data)
		
		# Вычисляем индексы слотов кузни
		var forge_start = inventory_data.inventory_slot_count + inventory_data.equipment_slot_count + inventory_data.quick_slot_count
		var input_1_index = forge_start + 0
		var input_2_index = forge_start + 1
		var output_index = forge_start + 2
		
		# Записываем результат в данные
		inventory_data.slots[output_index] = new_slot_data
		
		# Очищаем входные слоты в данных
		inventory_data.slots[input_1_index] = null
		inventory_data.slots[input_2_index] = null
		
		# Очищаем входные слоты в UI
		set_input_slot_1_data(null)
		set_input_slot_2_data(null)
		
		# Удаляем предметы из исходных слотов инвентаря (если они там были)
		consume_input_items()
		
		# Уведомляем об изменении данных
		inventory_data.slot_changed()
		update_forge_button_state()

func create_skill_item(base_item: ItemData) -> ItemData:
	if base_item.skill:
		return base_item
	if base_item is EquipableItemData:
		return base_item
	var new_item = ItemData.new()
	new_item.name = base_item.name + " (С Навыком)"
	new_item.description = base_item.description + "\nНавык добавлен!"
	new_item.texture = base_item.texture
	new_item.skill = base_item.skill
	return new_item

func consume_input_items() -> void:
	var slot_1_index = inventory_data.slots.find(input_slot_1.slot_data)
	var slot_2_index = inventory_data.slots.find(input_slot_2.slot_data)
	if slot_1_index != -1 and slot_1_index < inventory_data.inventory_slot_count:
		inventory_data.slots[slot_1_index] = null
	if slot_2_index != -1 and slot_2_index < inventory_data.inventory_slot_count:
		inventory_data.slots[slot_2_index] = null
	# Слоты кузни очищаются в _on_forge_button_pressed(), поэтому здесь их не трогаем
	inventory_data.slot_changed()

func forge_items(slot_1: SlotData, slot_2: SlotData) -> Dictionary:
	if slot_1 == null or slot_2 == null:
		return {"success": false, "message": "Оба слота должны быть заполнены!"}
	
	var item_1 = slot_1.item_data
	var item_2 = slot_2.item_data
	
	if item_1 == null or item_2 == null:
		return {"success": false, "message": "Один из слотов содержит некорректный предмет!"}
	
	if is_weapon(item_1) and is_skill_book(item_2):
		return attach_skill_to_weapon(item_1, item_2)
	elif is_weapon(item_2) and is_skill_book(item_1):
		return attach_skill_to_weapon(item_2, item_1)
	elif is_skill_book(item_1) and is_element_item(item_2):
		return combine_skill_with_element(item_1, item_2)
	elif is_skill_book(item_2) and is_element_item(item_1):
		return combine_skill_with_element(item_2, item_1)
	elif can_merge_skills(item_1, item_2):
		return merge_same_skill_books(item_1, item_2)
	
	return {"success": false, "message": "Неверная комбинация!"}

func can_merge_skills(item_1: ItemData, item_2: ItemData) -> bool:
	if not (is_skill_book(item_1) and is_skill_book(item_2)):
		return false
	var skill_1 = item_1.skill
	var skill_2 = item_2.skill
	if skill_1 == null or skill_2 == null:
		return false
	return skill_1.name == skill_2.name \
	and skill_1.level == skill_2.level \
	and skill_1.level < skill_1.max_level

func is_weapon(item: ItemData) -> bool:
	return item is EquipableItemData and item.type == EquipableItemData.Type.WEAPON

func is_skill_book(item: ItemData) -> bool:
	return item is SkillItemData and item.skill_item_type == SkillItemData.SkillItemType.SKILL

func is_element_item(item: ItemData) -> bool:
	return item is SkillItemData and item.skill_item_type == SkillItemData.SkillItemType.ELEMENT

func combine_skill_with_element(skill_book: SkillItemData, element_item: SkillItemData) -> Dictionary:
	var new_skill = skill_book.skill.duplicate()
	new_skill.element = element_item.element
	
	var new_item = SkillItemData.new()
	new_item.skill_item_type = SkillItemData.SkillItemType.SKILL
	new_item.name = skill_book.name + " (" + SkillResource.Element.keys()[new_skill.element] + ")"
	new_item.description = skill_book.description + " с элементом " + SkillResource.Element.keys()[new_skill.element]
	new_item.texture = skill_book.texture
	new_item.skill = new_skill
	
	return {
		"success": true,
		"message": "Создан " + new_item.name + "!",
		"output_item": new_item
	}

func attach_skill_to_weapon(weapon: EquipableItemData, skill_book: SkillItemData) -> Dictionary:
	var new_weapon = weapon.duplicate()
	new_weapon.skill = skill_book.skill.duplicate()
	new_weapon.name = weapon.name + " с " + skill_book.skill.name
	new_weapon.description = weapon.description + "\nНавык: " + skill_book.skill.get_description()
	
	return {
		"success": true,
		"message": "Сковано " + new_weapon.name + "!",
		"output_item": new_weapon
	}

func merge_same_skill_books(item_1: SkillItemData, item_2: SkillItemData) -> Dictionary:
	var base_skill = item_1.skill
	var chance = base_skill.upgrade_success_chance
	if randf() > chance:
		return {
			"success": false,
			"message": "Улучшение навыка '" + base_skill.name + "' не удалось!"
		}
	
	var new_skill = base_skill.duplicate()
	new_skill.level += 1
	
	var new_item = SkillItemData.new()
	new_item.skill_item_type = SkillItemData.SkillItemType.SKILL
	new_item.name = base_skill.name + " [Ур. " + str(new_skill.level) + "]"
	new_item.description = base_skill.description + " (Улучшен до уровня " + str(new_skill.level) + ")"
	new_item.texture = item_1.texture
	new_item.skill = new_skill
	
	return {
		"success": true,
		"message": "Навык '" + new_item.name + "' улучшен!",
		"output_item": new_item
	}


# В SkillForgeUI
func set_input_slot_1_data(value: SlotData) -> void:
	input_slot_1.set_slot_data(value)
	update_forge_button_state()

func set_input_slot_2_data(value: SlotData) -> void:
	input_slot_2.set_slot_data(value)
	update_forge_button_state()

func set_output_slot_data(value: SlotData) -> void:
	output_slot.set_slot_data(value)
	update_forge_button_state()
