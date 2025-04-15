class_name InventoryUI extends Control

const INVENTORY_SLOT = preload("res://GUI/Inventory/inventory_slot_ui.tscn")

var focus_index: int = 0
var hovered_item: InventorySlotUI
var selected_quick_slot: int = 0

@export var data: InventoryData

@onready var head_slot: InventorySlotUI = %Head
@onready var body_slot: InventorySlotUI = %Body
@onready var pants_slot: InventorySlotUI = %Pants
@onready var boots_slot: InventorySlotUI = %Boots
@onready var weapon_slot: InventorySlotUI = %Weapon
@onready var accessory_slot: InventorySlotUI = %Accessory
@onready var accessory2_slot: InventorySlotUI = %Accessory2
@onready var accessory3_slot: InventorySlotUI = %Accessory3

@onready var quick_slots: Array[InventorySlotUI] = [
	%QuickSlot1, %QuickSlot2, %QuickSlot3, %QuickSlot4, %QuickSlot5,
	%QuickSlot6, %QuickSlot7, %QuickSlot8, %QuickSlot9, %QuickSlot10
]

@onready var skill_forge_ui = $"../../../VBoxContainer/HBoxContainer/SkillForgeUI"

var equip_colors = {
	"head": Color(0, 0, 1),
	"body": Color(0, 1, 0),
	"pants": Color(1, 0, 0),
	"boots": Color(0.5, 0, 0.5),
	"weapon": Color(1, 0.5, 0),
	"accessory": Color(0, 1, 1),
	"accessory2": Color(1, 0, 1),
	"accessory3": Color(0.5, 0.5, 0)
}

var inventory_slots_ui: Array[InventorySlotUI] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Inventory.hidden.connect(clear_inventory)
	Inventory.showen.connect(update_inventory)
	initialize_inventory_slots()
	data.changed.connect(on_inventory_changed)
	data.equipment_changed.connect(on_inventory_changed)
	clear_inventory()
	update_quick_slot_selection()
	set_equip_colors()
	set_slot_types()
	if skill_forge_ui:
		skill_forge_ui.ready_completed.connect(update_forge_slots)

func _input(event: InputEvent) -> void:
	handle_quick_slot_input(event)
	if event.is_action_pressed("ui_accept"):
		unequip_selected_slot()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			selected_quick_slot = max(-1, selected_quick_slot - 1)
			if selected_quick_slot < -1:
				selected_quick_slot = quick_slots.size() - 1
			update_quick_slot_selection()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			selected_quick_slot = min(quick_slots.size() - 1, selected_quick_slot + 1)
			update_quick_slot_selection()

func initialize_inventory_slots() -> void:
	var slots = get_children()
	for i in data.inventory_slots().size():
		var slot = slots[i] as InventorySlotUI
		inventory_slots_ui.append(slot)

func set_slot_types() -> void:
	head_slot.slot_type = InventorySlotUI.ItemType.HEAD
	body_slot.slot_type = InventorySlotUI.ItemType.BODY
	weapon_slot.slot_type = InventorySlotUI.ItemType.WEAPON
	boots_slot.slot_type = InventorySlotUI.ItemType.BOOTS
	pants_slot.slot_type = InventorySlotUI.ItemType.PANTS
	accessory_slot.slot_type = InventorySlotUI.ItemType.ACCESSORY
	accessory2_slot.slot_type = InventorySlotUI.ItemType.ACCESSORY
	accessory3_slot.slot_type = InventorySlotUI.ItemType.ACCESSORY

func set_equip_colors() -> void:
	head_slot.modulate = equip_colors["head"]
	body_slot.modulate = equip_colors["body"]
	pants_slot.modulate = equip_colors["pants"]
	boots_slot.modulate = equip_colors["boots"]
	weapon_slot.modulate = equip_colors["weapon"]
	accessory_slot.modulate = equip_colors["accessory"]
	accessory2_slot.modulate = equip_colors["accessory2"]
	accessory3_slot.modulate = equip_colors["accessory3"]

func clear_inventory() -> void:
	for slot in inventory_slots_ui:
		slot.set_slot_data(null)

func update_inventory(apply_focus: bool = true) -> void:
	clear_inventory()
	update_inventory_slots()
	update_equipment_slots()
	update_quick_slots()
	update_forge_slots()
	if apply_focus and inventory_slots_ui.size() > 0:
		inventory_slots_ui[0].grab_focus()
	update_quick_slot_selection()
	if PlayerManager.player:
		PlayerManager.player.skill_manager.update_passive_skills()

func update_inventory_slots() -> void:
	var inventory_slots: Array[SlotData] = data.inventory_slots()
	for i in inventory_slots.size():
		inventory_slots_ui[i].set_slot_data(inventory_slots[i])
		connect_item_signals(inventory_slots_ui[i])

func update_equipment_slots() -> void:
	var e_slots: Array[SlotData] = data.equipment_slots()
	head_slot.set_slot_data(e_slots[0])
	body_slot.set_slot_data(e_slots[2])
	pants_slot.set_slot_data(e_slots[4])
	boots_slot.set_slot_data(e_slots[6])
	weapon_slot.set_slot_data(e_slots[1])
	accessory_slot.set_slot_data(e_slots[3])
	accessory2_slot.set_slot_data(e_slots[5])
	accessory3_slot.set_slot_data(e_slots[7])
	
	connect_item_signals(head_slot)
	connect_item_signals(body_slot)
	connect_item_signals(pants_slot)
	connect_item_signals(boots_slot)
	connect_item_signals(weapon_slot)
	connect_item_signals(accessory_slot)
	connect_item_signals(accessory2_slot)
	connect_item_signals(accessory3_slot)

func update_quick_slots() -> void:
	var q_slots: Array[SlotData] = data.quick_slots()
	for i in quick_slots.size():
		quick_slots[i].set_slot_data(q_slots[i])
		connect_item_signals(quick_slots[i])

func update_forge_slots() -> void:
	var f_slots: Array[SlotData] = data.forge_slots()
	skill_forge_ui.set_input_slot_1_data(f_slots[0])
	skill_forge_ui.set_input_slot_2_data(f_slots[1])
	skill_forge_ui.set_output_slot_data(f_slots[2])
	
	connect_item_signals(skill_forge_ui.input_slot_1)
	connect_item_signals(skill_forge_ui.input_slot_2)
	connect_item_signals(skill_forge_ui.output_slot)

func unequip_selected_slot() -> void:
	var focused_slot = get_focused_equipment_slot()
	if focused_slot and focused_slot.slot_data:
		var slot_index = get_slot_global_index(focused_slot)
		if slot_index != -1:
			data.unequip_item(slot_index)
			update_inventory(false)

func get_focused_equipment_slot() -> InventorySlotUI:
	var equipment_slots = [head_slot, body_slot, pants_slot, boots_slot, 
						  weapon_slot, accessory_slot, accessory2_slot, accessory3_slot]
	for slot in equipment_slots:
		if slot.has_focus():
			return slot
	return null

func handle_quick_slot_input(event: InputEvent) -> void:
	for i in range(10):
		if event.is_action_pressed("quick_slot" + str(i + 1)):
			if selected_quick_slot == i:
				data.use_quick_slot(i)
				update_quick_slot_selection()
			else:
				selected_quick_slot = i
				update_quick_slot_selection()
			return

func on_inventory_changed() -> void:
	update_inventory(false)

func connect_item_signals(item: InventorySlotUI) -> void:
	if not item.button_up.is_connected(_on_item_drop.bind(item)):
		item.button_up.connect(_on_item_drop.bind(item))
	if not item.mouse_entered.is_connected(_on_item_mouse_entered.bind(item)):
		item.mouse_entered.connect(_on_item_mouse_entered.bind(item))
	if not item.mouse_exited.is_connected(_on_item_mouse_exited):
		item.mouse_exited.connect(_on_item_mouse_exited)

func _on_item_drop(item: InventorySlotUI) -> void:
	if item == null or item.slot_data == null:
		print("No item or slot data")
		return

	var source_index = get_slot_global_index(item)
	if source_index == -1:
		print("Invalid source index for slot: ", item)
		return

	var source_data = data.get_slot(source_index)
	if source_data == null:
		print("No source data at index: ", source_index, " UI data: ", item.slot_data)
		return

	var equipment_start = data.inventory_slot_count
	var equipment_end = equipment_start + data.equipment_slot_count
	var is_equipment_slot = source_index >= equipment_start and source_index < equipment_end
	
	var forge_start = data.inventory_slot_count + data.equipment_slot_count + data.quick_slot_count
	var forge_end = forge_start + 3
	var is_forge_slot = source_index >= forge_start and source_index < forge_end

	if hovered_item != null and hovered_item != item:
		var target_index = get_slot_global_index(hovered_item)
		if target_index == -1:
			print("Invalid target index for slot: ", hovered_item)
			return
		
		var target_is_equipment = target_index >= equipment_start and target_index < equipment_end
		var target_is_forge = target_index >= forge_start and target_index < forge_end

		if target_is_equipment:
			if hovered_item.slot_type != -1 and source_data.item_data.type != hovered_item.slot_type:
				print("Item type mismatch for equipment slot")
				return
			if is_equipment_slot:
				data.unequip_item(source_index)
				source_data = data.get_slot(source_index)
			data.equip_item(source_data)
			update_inventory(false)
			return
		
		if target_is_forge:
			if hovered_item == skill_forge_ui.input_slot_1:
				var item_data = source_data.item_data
				if not (item_data is EquipableItemData and item_data.type == EquipableItemData.Type.WEAPON) and not (item_data is SkillItemData and item_data.skill_item_type == SkillItemData.SkillItemType.SKILL):
					print("Invalid item for input_slot_1")
					return
			elif hovered_item == skill_forge_ui.input_slot_2:
				var item_data = source_data.item_data
				if not (item_data is SkillItemData and (item_data.skill_item_type == SkillItemData.SkillItemType.SKILL or item_data.skill_item_type == SkillItemData.SkillItemType.ELEMENT)):
					print("Invalid item for input_slot_2")
					return
			elif hovered_item == skill_forge_ui.output_slot and data.slots[target_index] != null:
				print("Output slot is already occupied")
				return

		if is_equipment_slot:
			data.unequip_item(source_index)
			source_data = data.get_slot(source_index)
		
		data.swap_item_by_index(source_index, target_index)
		
		# Если перетаскиваем из output_slot, очищаем его в данных
		if source_index == forge_start + 2:  # output_slot
			data.slots[source_index] = null
		
		update_inventory(false)
		
		var f_slots = data.forge_slots()
		skill_forge_ui.set_input_slot_1_data(f_slots[0])
		skill_forge_ui.set_input_slot_2_data(f_slots[1])
		skill_forge_ui.set_output_slot_data(f_slots[2])
		return

	if is_equipment_slot:
		data.unequip_item(source_index)
		update_inventory(false)

func _on_item_mouse_entered(item: InventorySlotUI) -> void:
	hovered_item = item

func _on_item_mouse_exited() -> void:
	hovered_item = null

func get_slot_global_index(slot: InventorySlotUI) -> int:
	var inv_index = inventory_slots_ui.find(slot)
	if inv_index != -1:
		return inv_index
	
	var equipment_start = data.inventory_slot_count
	var equipment_map = {
		head_slot: equipment_start + 0,
		body_slot: equipment_start + 2,
		pants_slot: equipment_start + 4,
		boots_slot: equipment_start + 6,
		weapon_slot: equipment_start + 1,
		accessory_slot: equipment_start + 3,
		accessory2_slot: equipment_start + 5,
		accessory3_slot: equipment_start + 7
	}
	if slot in equipment_map:
		return equipment_map[slot]
	
	var quick_start = data.inventory_slot_count + data.equipment_slot_count
	var quick_index = quick_slots.find(slot)
	if quick_index != -1:
		return quick_start + quick_index
	
	var forge_start = data.inventory_slot_count + data.equipment_slot_count + data.quick_slot_count
	if slot == skill_forge_ui.input_slot_1:
		return forge_start + 0
	elif slot == skill_forge_ui.input_slot_2:
		return forge_start + 1
	elif slot == skill_forge_ui.output_slot:
		return forge_start + 2
	
	return -1

func update_quick_slot_selection() -> void:
	for i in quick_slots.size():
		quick_slots[i].modulate = Color(1, 1, 0, 1) if i == selected_quick_slot else Color(1, 1, 1, 1)

func get_selected_quick_slot() -> int:
	return selected_quick_slot
