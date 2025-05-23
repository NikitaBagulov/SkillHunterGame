class_name InventorySlotUI extends Button

enum ItemType {
	HEAD,
	BODY,
	WEAPON,
	ACCESSORY,
	BOOTS,
	PANTS,
}

var slot_data: SlotData
var slot_type: int = -1  # Тип слота из enum ItemType

var click_pos: Vector2 = Vector2.ZERO
var dragging: bool = false
var drag_texture: Control
var drag_threshhold: float = 16.0

@onready var texture: TextureRect = $TextureRect
@onready var label: Label = $Label
@onready var level_label: Label = $LevelLabel

func _ready() -> void:
	texture.texture = null
	label.text = ""
	level_label.text = ""
	pressed.connect(item_pressed)
	button_down.connect(on_button_down)
	button_up.connect(on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _process(delta):
	if dragging:
		drag_texture.position = get_local_mouse_position() - Vector2(16, 16)
		if outside_drag_threshhold():
			drag_texture.modulate.a = 0.5
		else:
			drag_texture.modulate.a = 0.0

func set_slot_data(value: SlotData) -> void:
	slot_data = value
	update_slot_display(slot_data)
	if slot_data == null:
		texture.texture = null
		label.text = ""
		return
	texture.texture = slot_data.item_data.texture
	if slot_data.item_data is EquipableItemData or slot_data.item_data is SkillItemData:
		label.text = ""
	else:
		label.text = str(slot_data.quantity)

func item_pressed() -> void:
	if slot_data and !outside_drag_threshhold():
		if slot_data.item_data:
			var item = slot_data.item_data
			if item is EquipableItemData:
				PlayerManager.INVENTORY_DATA.equip_item(slot_data)
				return
			var was_used = item.use()
			if !was_used:
				return
			slot_data.quantity -= 1
			if slot_data.quantity <= 0:
				PlayerManager.INVENTORY_DATA.slot_changed()
				set_slot_data(null)
			if slot_data == null:
				return
			label.text = str(slot_data.quantity)
			update_slot_display(slot_data)

func on_button_down() -> void:
	click_pos = get_global_mouse_position()
	dragging = true
	drag_texture = texture.duplicate()
	drag_texture.z_index = 10
	drag_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(drag_texture)

func on_button_up() -> void:
	dragging = false
	if drag_texture:
		drag_texture.free()

func outside_drag_threshhold() -> bool:
	if get_global_mouse_position().distance_to(click_pos) > drag_threshhold:
		return true
	return false

func is_inventory_slot() -> bool:
	return slot_type == -1

func _on_mouse_entered() -> void:
	pass

func _on_mouse_exited() -> void:
	pass

func update_slot_display(slot_data: SlotData) -> void:
	if slot_data and slot_data.item_data is SkillItemData:
		if slot_data.item_data.skill != null:
			var skill = slot_data.item_data.skill
			level_label.text = "Lv." + str(skill.level)
			level_label.visible = true
	else:
		level_label.visible = false
