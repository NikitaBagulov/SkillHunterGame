@tool

class_name TreasureChest extends Node2D

@export var item_data: ItemData: set = _set_item_data
@export var quantity: int = 1: set = _set_quantity

var is_open: bool = false

@onready var sprite: Sprite2D = $ItemSprite
@onready var label: Label = $ItemSprite/Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interact_area: Area2D = $Area2D

func _ready():
	_update_sprite()
	_update_label()
	if Engine.is_editor_hint():
		return
	interact_area.area_entered.connect(_on_area_enter)
	interact_area.area_exited.connect(_on_area_exit)
	set_chest_state()

func player_interact() -> void:
	if is_open:
		return
	is_open = true
	animation_player.play("open_chest")
	if item_data and quantity > 0:
		PlayerManager.INVENTORY_DATA.add_item(item_data, quantity)
	else:
		printerr("No Items in chest!")
		push_error("No Items in chest! Chest name: ", name)
	pass

func _on_area_enter(_area: Area2D) -> void:
	PlayerManager.interact_pressed.connect(player_interact)
	pass

func _on_area_exit(_area: Area2D) -> void:
	PlayerManager.interact_pressed.disconnect(player_interact)
	pass


func _set_item_data(value: ItemData) -> void:
	item_data = value
	_update_sprite()
	pass
	
func _set_quantity(value: int) -> void:
	quantity = value
	_update_label()
	pass
	
func _update_sprite():
	if item_data and sprite:
		sprite.texture = item_data.texture

func _update_label() -> void:
	if label:
		if quantity <= 1:
			label.text = ""
		else:
			label.text = "x" + str(quantity)

func set_chest_state() -> void:
	if is_open:
		animation_player.play("opened")
	else:
		animation_player.play("closed")
