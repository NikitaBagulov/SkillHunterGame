class_name MarketUI extends Control

const INVENTORY_SLOT = preload("res://GUI/Inventory/inventory_slot_ui.tscn")
const MARKET_SLOT = preload("res://GUI/Market/market_slot_ui.tscn")

var inventory_data: InventoryData = PlayerManager.INVENTORY_DATA

signal transaction_completed 
signal close_requested

@onready var inventory_container: GridContainer = %InventoryContainer
@onready var market_container: GridContainer = %MarketContainer
@onready var transaction_button: Button = %TransactionButton
@onready var close_button: Button = %CloseButton

var tooltip: PopupMenu

var inventory_slots_ui: Array[InventorySlotUI] = []
var market_slots_ui: Array[InventorySlotUI] = []
var selected_slot: InventorySlotUI
var selected_market_slot: InventorySlotUI

func _ready() -> void:
	initialize_slots()
	initialize_tooltip()
	transaction_button.pressed.connect(_on_transaction_pressed)
	close_button.pressed.connect(_on_close_pressed)
	inventory_data.data_changed.connect(update_inventory)
	visible = false

func initialize_slots() -> void:
	# Инициализация слотов инвентаря
	for i in inventory_data.inventory_slots().size():
		var slot = MARKET_SLOT.instantiate()
		inventory_container.add_child(slot)
		inventory_slots_ui.append(slot)
		slot.button_up.connect(_on_inventory_slot_clicked.bind(slot))
		slot.mouse_entered.connect(_on_slot_mouse_entered.bind(slot))
		slot.mouse_exited.connect(_on_slot_mouse_exited.bind(slot))

	# Инициализация слотов магазина (предположим, 20 слотов)
	for i in 20:
		var slot = MARKET_SLOT.instantiate()
		market_container.add_child(slot)
		market_slots_ui.append(slot)
		slot.button_up.connect(_on_market_slot_clicked.bind(slot))
		slot.mouse_entered.connect(_on_slot_mouse_entered.bind(slot))
		slot.mouse_exited.connect(_on_slot_mouse_exited.bind(slot))

func initialize_tooltip() -> void:
	tooltip = PopupMenu.new()
	add_child(tooltip)

func set_market_items(items: Array[ItemData]) -> void:
	for i in market_slots_ui.size():
		if i < items.size():
			var slot_data = SlotData.new()
			slot_data.item_data = items[i]
			slot_data.quantity = 1
			market_slots_ui[i].set_slot_data(slot_data)
		else:
			market_slots_ui[i].set_slot_data(null)
	update_inventory()

func update_inventory() -> void:
	var inv_slots = inventory_data.inventory_slots()
	for i in inventory_slots_ui.size():
		inventory_slots_ui[i].set_slot_data(inv_slots[i])
	update_transaction_button()

func _on_inventory_slot_clicked(slot: InventorySlotUI) -> void:
	selected_slot = slot
	selected_market_slot = null
	update_transaction_button()

func _on_market_slot_clicked(slot: InventorySlotUI) -> void:
	selected_market_slot = slot
	selected_slot = null
	update_transaction_button()

func _on_transaction_pressed() -> void:
	if selected_slot and selected_slot.slot_data:
		# Продажа предмета
		var slot_data = selected_slot.slot_data
		if slot_data.item_data.cost >= 0:  # Предполагаем, что cost - поле в ItemData
			PlayerManager.PLAYER_STATS.add_currency(slot_data.item_data.cost)
			slot_data.quantity -= 1
			if slot_data.quantity <= 0:
				var index = inventory_data.inventory_slots().find(slot_data)
				if index != -1:
					inventory_data.slots[index] = null
			inventory_data.data_changed.emit()
			transaction_completed.emit()
	elif selected_market_slot and selected_market_slot.slot_data:
		# Покупка предмета
		var slot_data = selected_market_slot.slot_data
		if PlayerManager.PLAYER_STATS.currency >= slot_data.item_data.cost:
			if inventory_data.add_item(slot_data.item_data, 1):
				PlayerManager.PLAYER_STATS.remove_currency(slot_data.item_data.cost)
				transaction_completed.emit()
	update_transaction_button()

func _on_close_pressed() -> void:
	close_requested.emit()

func update_transaction_button() -> void:
	transaction_button.disabled = !(selected_slot and selected_slot.slot_data) and !(selected_market_slot and selected_market_slot.slot_data)

func _on_slot_mouse_entered(slot: Control) -> void:
	if slot is InventorySlotUI and slot.slot_data:
		_show_tooltip(slot.slot_data.item_data, slot.global_position)

func _on_slot_mouse_exited(slot: Control) -> void:
	_hide_tooltip()

func _show_tooltip(item: ItemData, pos: Vector2) -> void:
	tooltip.clear()
	tooltip.add_item(item.name, -1)
	tooltip.add_separator()
	var description_lines = item.description.split("\n") if item.description else [""]
	for line in description_lines:
		tooltip.add_item(line, -1)
	tooltip.add_separator()
	tooltip.add_item("Цена: %d" % item.cost, -1)
	
	var viewport_size = get_viewport_rect().size
	var estimated_size = Vector2(200, 20 * (description_lines.size() + 4)) # Estimate: name, separator, description lines, separator, cost
	var new_pos = pos + Vector2(30, 30)
	
	# Adjust if tooltip would go off-screen
	if new_pos.x + estimated_size.x > viewport_size.x:
		new_pos.x = pos.x - estimated_size.x - 10
	if new_pos.y + estimated_size.y > viewport_size.y:
		new_pos.y = pos.y - estimated_size.y - 10
	
	# Ensure tooltip doesn't go off the left or top edge
	new_pos.x = max(0, new_pos.x)
	new_pos.y = max(0, new_pos.y)
	
	tooltip.popup(Rect2(new_pos, Vector2.ZERO))

func _hide_tooltip() -> void:
	tooltip.hide()
