class_name InventoryUI extends Control

const INVENTORYSlotUI = preload("res://GUI/Inventory/inventory_slot_ui.tscn")

var focus_index: int = 0
var hovered_item: InventorySlotUI
var selected_quick_slot: int = 0

var data: InventoryData = PlayerManager.INVENTORY_DATA

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

@onready var skill_forge_ui = $"../../../VBoxContainer/SkillForgeUI"

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
var tooltip: PopupMenu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Inventory.hidden.connect(clear_inventory)
	Inventory.showen.connect(update_inventory)
	initialize_inventory_slots()
	connect_inventory_signals()
	clear_inventory()
	update_quick_slot_selection()
	set_equip_colors()
	set_slot_types()
	if skill_forge_ui:
		skill_forge_ui.ready_completed.connect(update_forge_slots)
	
	SaveManager.load_completed.connect(_on_load_completed)

func show_tooltip(slot: InventorySlotUI, offset: Vector2 = Vector2(20, 0)) -> void:
	if slot.slot_data and slot.slot_data.item_data:
		# Create a new PopupMenu
		tooltip = PopupMenu.new()
		add_child(tooltip)
		
		var item_name = slot.slot_data.item_data.name
		var description = slot.slot_data.item_data.description if slot.slot_data.item_data.description else "..."
		
		if slot.slot_data.item_data is EquipableItemData and slot.slot_data.item_data.skill:
			description += "\nНавык: " + slot.slot_data.item_data.skill.name
		
		tooltip.add_item(item_name, -1)
		tooltip.add_separator()
		var lines = description.split("\n")
		for line in lines:
			tooltip.add_item(line, -1)
		
		var slot_global_pos = slot.global_position
		var viewport_size = get_viewport_rect().size
		
		# Estimate text size based on font
		var font = tooltip.get_theme_font("font") if tooltip.get_theme_font("font") else get_theme_default_font()
		var font_size = tooltip.get_theme_font_size("font_size") if tooltip.get_theme_font_size("font_size") else 16
		var max_width = 0.0
		var line_height = font.get_height(font_size)
		
		# Combine item_name with lines for width calculation
		var all_lines = PackedStringArray([item_name]) + lines
		for line in all_lines:
			var text_width = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			max_width = max(max_width, text_width)
		
		# Add padding and separator height
		var estimated_size = Vector2(max_width + 20, line_height * (lines.size() + 2) + 10)
		
		# Try positioning to the right of the slot
		var new_pos = slot_global_pos + offset + Vector2(slot.size.x, 0)
		var is_right_side = true
		
		# Adjust if it goes off the right edge
		if new_pos.x + estimated_size.x > viewport_size.x:
			# Try positioning to the left
			new_pos.x = slot_global_pos.x - estimated_size.x - offset.x
			is_right_side = false
			# Check if it goes off the left edge
			if new_pos.x < 0:
				# Revert to right side and rely on clamping
				new_pos.x = slot_global_pos.x + slot.size.x + offset.x
				is_right_side = true
		
		# Align top of tooltip with top of slot by default
		new_pos.y = slot_global_pos.y
		
		# Adjust vertical position if on the left side to avoid overlap
		if not is_right_side:
			# Check if tooltip goes off the bottom
			if new_pos.y + estimated_size.y > viewport_size.y:
				# Align bottom of tooltip with bottom of slot
				new_pos.y = slot_global_pos.y + slot.size.y - estimated_size.y
			# Check if tooltip goes off the top after adjustment
			if new_pos.y < 0:
				# Align top with viewport top
				new_pos.y = 0
		
		# Clamp to viewport
		new_pos.x = clamp(new_pos.x, 0, viewport_size.x - estimated_size.x)
		new_pos.y = clamp(new_pos.y, 0, viewport_size.y - estimated_size.y)
		
		tooltip.popup(Rect2(new_pos, Vector2.ZERO))


func hide_tooltip() -> void:
	if tooltip:
		tooltip.queue_free()
		tooltip = null

func connect_inventory_signals() -> void:
	if data.is_connected("changed", on_inventory_changed):
		data.changed.disconnect(on_inventory_changed)
	if data.is_connected("equipment_changed", on_inventory_changed):
		data.equipment_changed.disconnect(on_inventory_changed)
	
	data.changed.connect(on_inventory_changed)
	data.equipment_changed.connect(on_inventory_changed)

func _on_load_completed(success: bool) -> void:
	if not success:
		print("[InventoryUI] Load failed")
		return
	
	print("[InventoryUI] Load completed, restoring state")
	restore_state()

func restore_state() -> void:
	data = PlayerManager.INVENTORY_DATA
	connect_inventory_signals()
	update_inventory(false)
	print("[InventoryUI] Restored with %d slots" % data.slots.size())

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
		if event.is_action_pressed("quick_slot_" + str(i + 1)):
			if selected_quick_slot == i:
				data.use_quick_slot(i)
				EventBus.quick_slots_updated.emit()
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
	if item == null or !is_instance_valid(item) or !item is InventorySlotUI:
		return

	if item.slot_data == null:
		return

	var source_index = get_slot_global_index(item)
	if source_index == -1:
		return

	var source_data = data.get_slot(source_index)
	if source_data == null or source_data.item_data == null:
		return

	var equipment_start = data.inventory_slot_count
	var equipment_end = equipment_start + data.equipment_slot_count
	var is_equipment_slot = source_index >= equipment_start and source_index < equipment_end
	
	var forge_start = data.inventory_slot_count + data.equipment_slot_count + data.quick_slot_count
	var forge_end = forge_start + 3
	var is_forge_slot = source_index >= forge_start and source_index < forge_end

	if hovered_item != null and hovered_item != item and hovered_item is InventorySlotUI:
		var target_index = get_slot_global_index(hovered_item)
		if target_index == -1:
			return
		
		var target_is_equipment = target_index >= equipment_start and target_index < equipment_end
		var target_is_forge = target_index >= forge_start and target_index < forge_end

		if target_is_equipment:
			var target_slot_type = hovered_item.slot_type
			var source_item_type = source_data.item_data.type if source_data.item_data is EquipableItemData else null

			print("Target slot type:", target_slot_type)
			print("Source item type:", source_item_type)

			if target_slot_type != source_item_type:
				print("Ошибка: Типы не совпадают. Отмена перемещения.")
				return

			if hovered_item.slot_data != null and hovered_item.slot_data.item_data != null:
				var slot_target_index = get_slot_global_index(hovered_item)
				data.unequip_item(slot_target_index)

			if is_equipment_slot:
				data.unequip_item(source_index)

			data.swap_item_by_index(source_index, target_index)
			var target_data = data.get_slot(target_index)
			data.equip_item(target_data)

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
	show_tooltip(item)

func _on_item_mouse_exited() -> void:
	hovered_item = null
	hide_tooltip()

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
		EventBus.quick_slots_updated.emit()
		if i == selected_quick_slot:
			EventBus.quick_slot_selected.emit(selected_quick_slot)
			quick_slots[i].modulate = Color(1, 1, 0, 1) 
		else:
			quick_slots[i].modulate = Color(1, 1, 1, 1)

func get_selected_quick_slot() -> int:
	return selected_quick_slot
