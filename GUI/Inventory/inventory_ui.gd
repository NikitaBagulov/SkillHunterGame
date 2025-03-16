class_name InventoryUI extends Control

const INVENTORY_SLOT = preload("res://GUI/Inventory/inventory_slot_ui.tscn")

var focus_index: int = 0
var hovered_item: InventorySlotUI

@export var data: InventoryData

@onready var head_slot: InventorySlotUI = %Head
@onready var body_slot: InventorySlotUI = %Body
@onready var pants_slot: InventorySlotUI = %Pants
@onready var boots_slot: InventorySlotUI = %Boots
@onready var quick_slots: Array[InventorySlotUI] = [    %QuickSlot1, %QuickSlot2, %QuickSlot3, %QuickSlot4, %QuickSlot5,    %QuickSlot6, %QuickSlot7, %QuickSlot8, %QuickSlot9, %QuickSlot10]

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
	data.equipment_changed.connect( on_inventory_changed )
	pass # Replace with function body.

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
	
	# Обновление основного инвентаря
	var inventory_slots: Array[SlotData] = data.inventory_slots()
	for i in inventory_slots.size():
		inventory_slots_ui[i].set_slot_data(inventory_slots[i])
		connect_item_signals(inventory_slots_ui[i])

	# Обновление слотов экипировки
	var e_slots: Array[SlotData] = data.equipment_slots()
	head_slot.set_slot_data(e_slots[0])
	body_slot.set_slot_data(e_slots[1])
	pants_slot.set_slot_data(e_slots[2])
	boots_slot.set_slot_data(e_slots[3])
	connect_item_signals(head_slot)
	connect_item_signals(body_slot)
	connect_item_signals(pants_slot)
	connect_item_signals(boots_slot)

	# Обновление слотов быстрого доступа
	var q_slots: Array[SlotData] = data.quick_slots()
	for i in quick_slots.size():
		quick_slots[i].set_slot_data(q_slots[i])
		connect_item_signals(quick_slots[i])

	if apply_focus and inventory_slots_ui.size() > 0:
		inventory_slots_ui[0].grab_focus()

# Новая функция для обработки ввода
func _input(event):
	# Пример привязки клавиш 1-0 к слотам быстрого доступа
	for i in range(10):
		if event.is_action_pressed("quick_slot_" + str(i + 1)):
			data.use_quick_slot(i)

func item_focused() -> void:
	for i in get_child_count():
		if get_child(i).has_focus():
			focus_index = i
			return
			
func on_inventory_changed() -> void:
	update_inventory( false )

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
	
	# Вычисляем правильные индексы в массиве slots
	var source_index = get_slot_global_index(item)
	var target_index = get_slot_global_index(hovered_item)
	print(source_index, ":", target_index)
	if source_index != -1 and target_index != -1:
		data.swap_item_by_index(source_index, target_index)
		update_inventory(false)

func _on_item_mouse_entered(item: InventorySlotUI) -> void:
	hovered_item = item
	pass

func _on_item_mouse_exited() -> void:
	hovered_item = null
	pass
func get_slot_global_index(slot: InventorySlotUI) -> int:
	# Проверяем слоты основного инвентаря
	var inv_index = inventory_slots_ui.find(slot)
	if inv_index != -1:
		return inv_index  # Индекс в основном инвентаре совпадает с началом data.slots
	
	# Проверяем слоты экипировки
	var equipment_start = data.slots.size() - data.equipment_slot_count - data.quick_slot_count
	if slot == head_slot:
		return equipment_start + 0
	if slot == body_slot:
		return equipment_start + 1
	if slot == pants_slot:
		return equipment_start + 2
	if slot == boots_slot:
		return equipment_start + 3
	
	# Проверяем быстрые слоты
	var quick_start = data.slots.size() - data.quick_slot_count
	var quick_index = quick_slots.find(slot)
	if quick_index != -1:
		return quick_start + quick_index
	
	print("Slot not found: ", slot)
	return -1  # Слот не найден
