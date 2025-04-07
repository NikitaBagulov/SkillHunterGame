class_name InventoryData extends Resource

signal equipment_changed
signal item_added(slot: SlotData)
signal item_removed(slot: SlotData)

@export var slots: Array[SlotData]
var equipment_slot_count: int = 8
var quick_slot_count: int = 10

func _init():
	connect_slots()
	# Assume inventory_slots_size (e.g., 20) is the desired inventory size
	var inventory_slots_size: int = 20  # Adjust this based on your design
	var total_size: int = inventory_slots_size + equipment_slot_count + quick_slot_count
	if slots.size() != total_size:
		slots.resize(total_size)

func inventory_slots() -> Array[SlotData]:
	return slots.slice(0, slots.size() - equipment_slot_count - quick_slot_count)

func equipment_slots() -> Array[SlotData]:
	return slots.slice(slots.size() - equipment_slot_count - quick_slot_count, slots.size() - quick_slot_count)

func quick_slots() -> Array[SlotData]:
	return slots.slice(slots.size() - quick_slot_count, slots.size())

func use_quick_slot(index: int) -> bool:
	if index < 0 || index >= quick_slot_count:
		return false
	
	var quick_slot_index = slots.size() - quick_slot_count + index
	var slot = slots[quick_slot_index]
	
	if slot != null && slot.item_data != null:
		if slot.item_data is EquipableItemData:
			# Equip any equipable item
			equip_item(slot)
			return true
		elif slot.item_data is ItemData and not slot.item_data is EquipableItemData:
			# Use consumable
			slot.quantity -= 1
			slot_changed()
			return true
	return false

func equip_item(slot: SlotData) -> void:
	if slot == null or not slot.item_data is EquipableItemData:
		return
	
	var item: EquipableItemData = slot.item_data
	var slot_index: int = slots.find(slot)
	if slot_index == -1:
		return
	
	var equipment_start: int = slots.size() - equipment_slot_count - quick_slot_count
	var target_index: int = -1
	
	match item.type:
		EquipableItemData.Type.HEAD:
			target_index = equipment_start + 0  # First slot: Head
		EquipableItemData.Type.WEAPON:
			target_index = equipment_start + 1  # Second slot: Weapon
		EquipableItemData.Type.BODY:
			target_index = equipment_start + 2  # Third slot: Body
		EquipableItemData.Type.PANTS:
			target_index = equipment_start + 4  # Fifth slot: Pants
		EquipableItemData.Type.BOOTS:
			target_index = equipment_start + 6  # Sixth slot: Boots
		EquipableItemData.Type.ACCESSORY:
			for i in [3, 5, 7]:
				if slots[equipment_start + i] == null:
					target_index = equipment_start + i
					break
			if target_index == -1:
				target_index = equipment_start + 3
	
	if target_index != -1:
		var unequipped_slot: SlotData = slots[target_index]
		# Remove passive skill from the unequipped item (if any)
		if unequipped_slot and unequipped_slot.item_data and unequipped_slot.item_data.skill:
			if unequipped_slot.item_data.skill.type == SkillResource.SkillType.PASSIVE:
				unequipped_slot.item_data.skill.remove_passive(PlayerManager.player)
		
		# Equip the new item
		slots[target_index] = slot
		slots[slot_index] = unequipped_slot
		
		# Apply passive skill from the newly equipped item (if any)
		if item.skill and item.skill.type == SkillResource.SkillType.PASSIVE:
			item.skill.apply_passive(PlayerManager.player)
		
		equipment_changed.emit()
		PlayerManager.update_equipment_damage()

func add_item(item: ItemData, count: int = 1) -> bool:
	for slot in slots:
		if slot and slot.item_data == item:
			slot.quantity += count
			return true
	for i in inventory_slots().size():
		if slots[i] == null:
			var new_slot = SlotData.new()
			new_slot.item_data = item
			new_slot.quantity = count
			slots[i] = new_slot
			new_slot.changed.connect(slot_changed)
			item_added.emit(new_slot)
			return true
	print("inventory was full!")
	return false

func connect_slots() -> void:
	for slot in slots:
		if slot:
			slot.changed.connect(slot_changed)

func slot_changed() -> void:
	for slot in slots:
		if slot and slot.quantity < 1:
			slot.changed.disconnect(slot_changed)
			var index = slots.find(slot)
			item_removed.emit(slot)
			slots[index] = null
	emit_changed()

func get_save_data() -> Array:
	var item_save: Array = []
	for i in slots.size():
		item_save.append(item_to_save(slots[i]))
	return item_save

func item_to_save(slot: SlotData) -> Dictionary:
	var result = {"item": "", "quantity": 0}
	if slot != null:
		result.quantity = slot.quantity
		if slot.item_data != null:
			result.item = slot.item_data.resource_path
	return result

func parse_save_data(save_data: Array) -> void:
	var array_size = slots.size()
	slots.clear()
	slots.resize(array_size)
	for i in save_data.size():
		slots[i] = item_from_save(save_data[i])
	connect_slots()

func item_from_save(save_object: Dictionary) -> SlotData:
	if save_object.item == "":
		return null
	var new_slot: SlotData = SlotData.new()
	new_slot.item_data = load(save_object.item)
	new_slot.quantity = int(save_object.quantity)
	return new_slot

func swap_item_by_index(i1: int, i2: int) -> void:
	var temp: SlotData = slots[i1]
	slots[i1] = slots[i2]
	slots[i2] = temp

func get_attack_bonus() -> int:
	return get_equipment_bonus(EquipableItemModifier.Type.ATTACK)

func get_attack_bonus_diff(item: EquipableItemData) -> int:
	var before: int = get_attack_bonus()
	var after: int = get_equipment_bonus(EquipableItemModifier.Type.ATTACK, item)
	return after - before

func get_defense_bonus() -> int:
	return get_equipment_bonus(EquipableItemModifier.Type.DEFENSE)

func get_defense_bonus_diff(item: EquipableItemData) -> int:
	var before: int = get_defense_bonus()
	var after: int = get_equipment_bonus(EquipableItemModifier.Type.DEFENSE, item)
	return after - before

func get_equipment_bonus(bonus_type: EquipableItemModifier.Type, compare: EquipableItemData = null) -> int:
	var bonus: int = 0
	for s in equipment_slots():
		if s == null:
			continue
		var e: EquipableItemData = s.item_data
		if compare and e.type == compare.type:
			e = compare
		for m in e.modifiers:
			if m.type == bonus_type:
				bonus += m.value
	return bonus
	
func get_equipped_weapon_damage_bonus() -> int:
	var weapon_slot = equipment_slots()[1]  # Индекс слота для оружия (например, 1)
	if weapon_slot and weapon_slot.item_data:
		return weapon_slot.item_data.get_attack_bonus()
	return 0
	
func get_slot(index: int) -> SlotData:
	if index < 0 || index >= slots.size():
		print("ERROR: Invalid slot index", index)
		return null
	return slots[index]

func get_equipped_weapon() -> EquipableItemData:
	var equipment = equipment_slots()
	if equipment.size() > 1:  # Слот оружия находится под индексом 1
		var weapon_slot = equipment[1]
		if weapon_slot and weapon_slot.item_data:
			var texture=weapon_slot.item_data.texture
			return weapon_slot.item_data
	return null

# Метод для получения текстуры оружия
func get_equipped_weapon_texture() -> Texture:
	var weapon = get_equipped_weapon()
	return weapon.texture if weapon else null

func unequip_item(equipment_index: int) -> void:
	var slot_data = slots[equipment_index]
	if slot_data == null:
		return
	
	# Remove passive skill effect before moving the item
	if slot_data.item_data and slot_data.item_data.skill:
		if slot_data.item_data.skill.type == SkillResource.SkillType.PASSIVE:
			slot_data.item_data.skill.remove_passive(PlayerManager.player)
	
	# Move the item to the inventory
	for i in range(slots.size() - equipment_slot_count - quick_slot_count):
		if slots[i] == null:
			slots[i] = slot_data
			slots[equipment_index] = null
			equipment_changed.emit()
			changed.emit()
			PlayerManager.update_equipment_damage()
			PlayerManager._update_weapon_texture()
			return
	print("No free inventory slot available!")
