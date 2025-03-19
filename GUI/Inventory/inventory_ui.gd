class_name InventoryUI extends Control

const INVENTORY_SLOT = preload("res://GUI/Inventory/inventory_slot_ui.tscn")

var focus_index: int = 0
var hovered_item: InventorySlotUI
var selected_quick_slot: int = -1

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

var equip_colors = {
	"head": Color(0, 0, 1),       # Голубой для головы
	"body": Color(0, 1, 0),       # Зеленый для тела
	"pants": Color(1, 0, 0),      # Красный для брюк
	"boots": Color(0.5, 0, 0.5),  # Фиолетовый для обуви
	"weapon": Color(1, 0.5, 0),   # Оранжевый для оружия
	"accessory": Color(0, 1, 1),  # Сине-зеленый для аксессуаров
	"accessory2": Color(1, 0, 1), # Мароновый для второго аксессуара
	"accessory3": Color(0.5, 0.5, 0) # Серый для третьего аксессуара
}

var inventory_slots_ui: Array[InventorySlotUI] = []

func _ready():
	Inventory.hidden.connect(clear_inventory)
	Inventory.showen.connect(update_inventory)
	
	var slots = get_children()
	for i in data.inventory_slots().size():
		var slot = slots[i] as InventorySlotUI
		inventory_slots_ui.append(slot)
	
	clear_inventory()
	data.changed.connect(on_inventory_changed)
	data.equipment_changed.connect(on_inventory_changed)
	update_quick_slot_selection()
	set_equip_colors()
	
	head_slot.slot_type = InventorySlotUI.ItemType.HEAD
	body_slot.slot_type = InventorySlotUI.ItemType.BODY
	weapon_slot.slot_type = InventorySlotUI.ItemType.WEAPON
	boots_slot.slot_type = InventorySlotUI.ItemType.BOOTS
	pants_slot.slot_type = InventorySlotUI.ItemType.PANTS
	accessory_slot.slot_type = InventorySlotUI.ItemType.ACCESSORY
	accessory2_slot.slot_type = InventorySlotUI.ItemType.ACCESSORY
	accessory3_slot.slot_type = InventorySlotUI.ItemType.ACCESSORY

func set_equip_colors():
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
	
	var inventory_slots: Array[SlotData] = data.inventory_slots()
	for i in inventory_slots.size():
		inventory_slots_ui[i].set_slot_data(inventory_slots[i])
		connect_item_signals(inventory_slots_ui[i])
	set_equip_colors()
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
	
	var q_slots: Array[SlotData] = data.quick_slots()
	for i in quick_slots.size():
		quick_slots[i].set_slot_data(q_slots[i])
		connect_item_signals(quick_slots[i])
	
	if apply_focus and inventory_slots_ui.size() > 0:
		inventory_slots_ui[0].grab_focus()
	
	update_quick_slot_selection()

func input(event):
	for i in range(10):
		if event.is_action_pressed("quick_slot" + str(i + 1)):
			if selected_quick_slot == i:
				data.use_quick_slot(i)
				update_quick_slot_selection()
			else:
				selected_quick_slot = i
				update_quick_slot_selection()
			return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			selected_quick_slot = max(-1, selected_quick_slot - 1)
			if selected_quick_slot < -1:
				selected_quick_slot = quick_slots.size() - 1
			update_quick_slot_selection()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			selected_quick_slot = min(quick_slots.size() - 1, selected_quick_slot + 1)
			update_quick_slot_selection()

func item_focused() -> void:
	for i in inventory_slots_ui.size():
		if inventory_slots_ui[i].has_focus():
			focus_index = i
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
	if item == null or item == hovered_item or hovered_item == null:
		return

	var source_index = get_slot_global_index(item)
	var target_index = get_slot_global_index(hovered_item)

	if source_index != -1 && target_index != -1:
		# Получаем данные предметов
		var source_data = data.get_slot(source_index)
		var target_data = data.get_slot(target_index)

		# Проверка типа слота для целевого элемента
		if hovered_item.slot_type != -1:
			if source_data.item_data.type != hovered_item.slot_type:
				# Попытка перетащить в неподходящий слот
				return

		# Обменяем только если целевой слот совместим
		data.swap_item_by_index(source_index, target_index)
		update_inventory(false)

func _on_item_mouse_entered(item: InventorySlotUI) -> void:
	hovered_item = item

func _on_item_mouse_exited() -> void:
	hovered_item = null

func get_slot_global_index(slot: InventorySlotUI) -> int:
	var inv_index = inventory_slots_ui.find(slot)
	if inv_index != -1:
		return inv_index
	
	var equipment_start = data.slots.size() - data.equipment_slot_count - data.quick_slot_count
	if slot == head_slot:
		return equipment_start + 0
	if slot == body_slot:
		return equipment_start + 2
	if slot == pants_slot:
		return equipment_start + 4
	if slot == boots_slot:
		return equipment_start + 6
	if slot == weapon_slot:
		return equipment_start + 1
	if slot == accessory_slot:
		return equipment_start + 3
	if slot == accessory2_slot:
		return equipment_start + 5
	if slot == accessory3_slot:
		return equipment_start + 7
	
	var quick_start = data.slots.size() - data.quick_slot_count
	var quick_index = quick_slots.find(slot)
	if quick_index != -1:
		return quick_start + quick_index
	
	print("Slot not found: ", slot)
	return -1

func update_quick_slot_selection() -> void:
	for i in quick_slots.size():
		if i == selected_quick_slot:
			quick_slots[i].modulate = Color(1, 1, 0, 1)
		else:
			quick_slots[i].modulate = Color(1, 1, 1, 1)

func get_selected_quick_slot() -> int:
	return selected_quick_slot
