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

var tooltip: PopupPanel
var title_label: Label  # Ссылка на узел названия
var desc_label: Label   # Ссылка на узел описания

@onready var texture: TextureRect = $TextureRect
@onready var label: Label = $Label

func _ready() -> void:
	texture.texture = null
	label.text = ""
	pressed.connect(item_pressed)
	button_down.connect(on_button_down)
	button_up.connect(on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Создаем всплывающее окно
	tooltip = PopupPanel.new()
	var panel_content = VBoxContainer.new()
	title_label = Label.new()
	desc_label = Label.new()
	title_label.name = "TitleLabel"
	desc_label.name = "DescLabel"
	panel_content.add_child(title_label)
	panel_content.add_child(desc_label)
	tooltip.add_child(panel_content)
	tooltip.hide()
	add_child(tooltip)

func _process(delta):
	if dragging:
		drag_texture.position = get_local_mouse_position() - Vector2(16, 16)
		if outside_drag_threshhold():
			drag_texture.modulate.a = 0.5
		else:
			drag_texture.modulate.a = 0.0

func set_slot_data(value: SlotData) -> void:
	slot_data = value
	if slot_data == null:
		texture.texture = null
		label.text = ""
		hide_tooltip()
		return
	texture.texture = slot_data.item_data.texture
	if slot_data.item_data is EquipableItemData:
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
			if slot_data == null:
				return
			label.text = str(slot_data.quantity)

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

# Обработчики наведения мыши
func _on_mouse_entered() -> void:
	show_tooltip()

func _on_mouse_exited() -> void:
	hide_tooltip()

# Показ всплывающего окна
func show_tooltip(offset: Vector2 = Vector2(10, 10)) -> void:
	if slot_data and slot_data.item_data and not tooltip.visible:
		title_label.text = slot_data.item_data.name
		desc_label.text = slot_data.item_data.description if slot_data.item_data.description else "No description"
		if slot_data.item_data is EquipableItemData and slot_data.item_data.skill:
			desc_label.text += "\nSkill: " + slot_data.item_data.skill.get_description()
		
		tooltip.popup()  # Показываем, чтобы получить размер
		await get_tree().process_frame  # Ждем кадр для точного размера
		
		# Calculate position in global coordinates
		var viewport_size = get_viewport_rect().size
		var tooltip_size = tooltip.size
		var pos = get_global_mouse_position()
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
		tooltip.position = new_pos - global_position

# Скрытие всплывающего окна
func hide_tooltip() -> void:
	tooltip.hide()
