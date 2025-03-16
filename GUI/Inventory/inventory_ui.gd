class_name InventoryUI extends Control

const INVENTORY_SLOT = preload("res://GUI/Inventory/inventory_slot_ui.tscn")

var focus_index: int = 0
var hovered_item: InventorySlotUI

@export var data: InventoryData

@onready var head_slot: InventorySlotUI = %Head
@onready var body_slot: InventorySlotUI = %Body
@onready var pants_slot: InventorySlotUI = %Pants
@onready var boots_slot: InventorySlotUI = %Boots

func _ready():
	Inventory.hidden.connect(clear_inventory)
	Inventory.showen.connect(update_inventory)
	clear_inventory()
	data.changed.connect(on_inventory_changed)
	data.equipment_changed.connect( on_inventory_changed )
	pass # Replace with function body.

func clear_inventory() -> void:
	for child in get_children():
		child.set_slot_data( null )
		
func update_inventory( apply_focus : bool = true ) -> void:
	clear_inventory()
	var inventory_slots : Array[ SlotData ] = data.inventory_slots()
	var slots = get_children()
	for i in inventory_slots.size():
		var slot : InventorySlotUI = slots[i]
		slot.set_slot_data( inventory_slots[ i ] )
		connect_item_signals(slot)
	
	# Update equipment slots
	var e_slots : Array[ SlotData ] = data.equipment_slots()
	head_slot.set_slot_data( e_slots[ 0 ] )
	body_slot.set_slot_data( e_slots[ 1 ] )
	pants_slot.set_slot_data( e_slots[ 2 ] )
	boots_slot.set_slot_data( e_slots[ 3 ] )
	
	if apply_focus:
		get_child( 0 ).grab_focus()

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
	data.swap_item_by_index(item.get_index(), hovered_item.get_index())
	update_inventory(false)
	pass

func _on_item_mouse_entered(item: InventorySlotUI) -> void:
	hovered_item = item
	pass

func _on_item_mouse_exited() -> void:
	hovered_item = null
	pass
