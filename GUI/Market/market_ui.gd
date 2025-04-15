# MarketUI.gd
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

@onready var tooltip_panel: PopupPanel = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/TooltipPanel
@onready var title: Label = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/TooltipPanel/VBoxContainer/Title
@onready var description: Label = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/TooltipPanel/VBoxContainer/Description

@onready var cost: Label = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/TooltipPanel/VBoxContainer/Cost



var inventory_slots_ui: Array[InventorySlotUI] = []
var market_slots_ui: Array[InventorySlotUI] = []
var selected_slot: InventorySlotUI
var selected_market_slot: InventorySlotUI

func _ready() -> void:
	initialize_slots()
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

	# Инициализация слотов магазина (предположим, 8 слотов)
	for i in 20:
		var slot = MARKET_SLOT.instantiate()
		market_container.add_child(slot)
		market_slots_ui.append(slot)
		slot.button_up.connect(_on_market_slot_clicked.bind(slot))
		slot.mouse_entered.connect(_on_slot_mouse_entered.bind(slot))
		slot.mouse_exited.connect(_on_slot_mouse_exited.bind(slot))

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
	elif slot is InventorySlotUI and slot.slot_data:
		_show_tooltip(slot.slot_data.item_data, slot.global_position)

func _on_slot_mouse_exited(slot: Control) -> void:
	_hide_tooltip()

func _show_tooltip(item: ItemData, pos: Vector2) -> void:
	title.text = item.name
	description.text = item.description
	cost.text = "Cost: %d" % item.cost
	
	# Show the popup
	tooltip_panel.popup()
	
	# Wait for size calculation
	await get_tree().process_frame
	
	# Calculate position in global coordinates
	var viewport_size = get_viewport_rect().size
	var tooltip_size = tooltip_panel.size
	var new_pos = pos + Vector2(30, 30)
	
	# Adjust if tooltip would go off-screen
	if new_pos.x + tooltip_size.x > viewport_size.x:
		new_pos.x = pos.x - tooltip_size.x - 10  # Place to the left of the slot
	if new_pos.y + tooltip_size.y > viewport_size.y:
		new_pos.y = pos.y - tooltip_size.y - 10  # Place above the slot
	
	# Ensure tooltip doesn't go off the left or top edge
	new_pos.x = max(0, new_pos.x)
	new_pos.y = max(0, new_pos.y)
	
	# Convert to local coordinates relative to MarketUI (root of the UI)
	tooltip_panel.position = new_pos - global_position

func _hide_tooltip() -> void:
	tooltip_panel.hide()
