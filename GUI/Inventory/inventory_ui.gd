class_name InventoryUI extends Control

const INVENTORY_SLOT = preload("res://GUI/Inventory/inventory_slot_ui.tscn")

var focus_index: int = 0

@export var data: InventoryData

@onready var pause_menu


func _ready():
	Inventory.hidden.connect(clear_inventory)
	Inventory.showen.connect(update_inventory)
	clear_inventory()
	data.changed.connect(on_inventory_changed)
	pass # Replace with function body.

func clear_inventory() -> void:
	for child in get_children():
		child.queue_free()
		
func update_inventory(i: int = 0) -> void:
	print(data.slots.size())
	for slot in data.slots:
		
		var new_slot = INVENTORY_SLOT.instantiate()
		add_child(new_slot)
		new_slot.set_slot_data(slot)
		new_slot.focus_entered.connect(item_focused)
	
	await get_tree().process_frame
	get_child(i).grab_focus()

func item_focused() -> void:
	for i in get_child_count():
		if get_child(i).has_focus():
			focus_index = i
			return
			
		

func on_inventory_changed() -> void:
	#var i = focus_index
	clear_inventory()
	update_inventory(focus_index)
