class_name InventoryUI extends Control

const INVENTORY_SLOT = preload("res://GUI/Inventory/inventory_slot_ui.tscn")

var focus_index: int = 0
var hovered_item: InventorySlotUI
var selected_quick_slot: int = -1  # Индекс выбранного слота быстрого доступа (-1 = ничего не выбрано)

@export var data: InventoryData

@onready var head_slot: InventorySlotUI = %Head
@onready var body_slot: InventorySlotUI = %Body
@onready var pants_slot: InventorySlotUI = %Pants
@onready var boots_slot: InventorySlotUI = %Boots
@onready var quick_slots: Array[InventorySlotUI] = [
	%QuickSlot1, %QuickSlot2, %QuickSlot3, %QuickSlot4, %QuickSlot5,
	%QuickSlot6, %QuickSlot7, %QuickSlot8, %QuickSlot9, %QuickSlot10
]

var inventory_slots_ui: Array[InventorySlotUI] = []

func _ready():
	Inventory.hidden.connect(clear_inventory)
	Inventory.showen.connect(update_inventory)  # Исправлено showen -> shown
	
	var slots = get_children()
	for i in data.inventory_slots().size():
		var slot = slots[i] as InventorySlotUI
		inventory_slots_ui.append(slot)
	
	clear_inventory()
	data.changed.connect(on_inventory_changed)
	data.equipment_changed.connect(on_inventory_changed)
	update_quick_slot_selection()

func clear_inventory() -> void:
	for slot in inventory_slots_ui:
		slot.set_slot_data(null)
	#head_slot.set_slot_data(null)
	#body_slot.set_slot_data(null)
	#pants_slot.set_slot_data(null)
	#boots_slot.set_slot_data(null)
	#for slot in quick_slots:
		#slot.set_slot_data(null)

func update_inventory(apply_focus: bool = true) -> void:
	clear_inventory()
	
	var inventory_slots: Array[SlotData] = data.inventory_slots()
	for i in inventory_slots.size():
		inventory_slots_ui[i].set_slot_data(inventory_slots[i])
		connect_item_signals(inventory_slots_ui[i])

	var e_slots: Array[SlotData] = data.equipment_slots()
	head_slot.set_slot_data(e_slots[0])
	body_slot.set_slot_data(e_slots[1])
	pants_slot.set_slot_data(e_slots[2])
	boots_slot.set_slot_data(e_slots[3])
	connect_item_signals(head_slot)
	connect_item_signals(body_slot)
	connect_item_signals(pants_slot)
	connect_item_signals(boots_slot)

	var q_slots: Array[SlotData] = data.quick_slots()
	for i in quick_slots.size():
		quick_slots[i].set_slot_data(q_slots[i])
		connect_item_signals(quick_slots[i])

	if apply_focus and inventory_slots_ui.size() > 0:
		inventory_slots_ui[0].grab_focus()
	
	update_quick_slot_selection()

func _input(event):
	# Обработка клавиш 1-0 для выбора и активации
	for i in range(10):
		if event.is_action_pressed("quick_slot_" + str(i + 1)):
			if selected_quick_slot == i:
				# Второе нажатие - активация
				data.use_quick_slot(i)
				update_quick_slot_selection()
			else:
				# Первое нажатие - выбор
				selected_quick_slot = i
				update_quick_slot_selection()
			return

	# Обработка колесика мыши
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
	print("Source:", source_index, " Target:", target_index)
	if source_index != -1 and target_index != -1:
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
		return equipment_start + 1
	if slot == pants_slot:
		return equipment_start + 2
	if slot == boots_slot:
		return equipment_start + 3
	
	var quick_start = data.slots.size() - data.quick_slot_count
	var quick_index = quick_slots.find(slot)
	if quick_index != -1:
		return quick_start + quick_index
	
	print("Slot not found: ", slot)
	return -1

# Новая функция для визуального обновления выбранного слота
func update_quick_slot_selection() -> void:
	for i in quick_slots.size():
		if i == selected_quick_slot:
			quick_slots[i].modulate = Color(1, 1, 0, 1)  # Желтый цвет для выбранного слота
		else:
			quick_slots[i].modulate = Color(1, 1, 1, 1)  # Белый цвет для остальных
