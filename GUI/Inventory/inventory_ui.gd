class_name InventoryUI extends Control

const INVENTORY_SLOT = preload("res://GUI/Inventory/inventory_slot_ui.tscn")

# Переменные состояния
var focus_index: int = 0  # Индекс слота в фокусе
var hovered_item: InventorySlotUI  # Слот под курсором
var selected_quick_slot: int = 0  # Выбранный быстрый слот

@export var data: InventoryData  # Данные инвентаря

# Ссылки на слоты экипировки
@onready var head_slot: InventorySlotUI = %Head
@onready var body_slot: InventorySlotUI = %Body
@onready var pants_slot: InventorySlotUI = %Pants
@onready var boots_slot: InventorySlotUI = %Boots
@onready var weapon_slot: InventorySlotUI = %Weapon
@onready var accessory_slot: InventorySlotUI = %Accessory
@onready var accessory2_slot: InventorySlotUI = %Accessory2
@onready var accessory3_slot: InventorySlotUI = %Accessory3

# Массив быстрых слотов
@onready var quick_slots: Array[InventorySlotUI] = [
	%QuickSlot1, %QuickSlot2, %QuickSlot3, %QuickSlot4, %QuickSlot5,
	%QuickSlot6, %QuickSlot7, %QuickSlot8, %QuickSlot9, %QuickSlot10
]

# Цвета для визуального различия слотов экипировки
var equip_colors = {
	"head": Color(0, 0, 1),       # Голубой для головы
	"body": Color(0, 1, 0),       # Зеленый для тела
	"pants": Color(1, 0, 0),      # Красный для брюк
	"boots": Color(0.5, 0, 0.5),  # Фиолетовый для обуви
	"weapon": Color(1, 0.5, 0),   # Оранжевый для оружия
	"accessory": Color(0, 1, 1),  # Бирюзовый для аксессуаров
	"accessory2": Color(1, 0, 1), # Пурпурный для второго аксессуара
	"accessory3": Color(0.5, 0.5, 0) # Оливковый для третьего аксессуара
}

var inventory_slots_ui: Array[InventorySlotUI] = []  # Массив UI слотов инвентаря

# Инициализация при загрузке
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Подключение сигналов инвентаря
	Inventory.hidden.connect(clear_inventory)
	Inventory.showen.connect(update_inventory)
	
	# Инициализация слотов инвентаря
	initialize_inventory_slots()
	
	# Подключение сигналов изменения данных
	data.changed.connect(on_inventory_changed)
	data.equipment_changed.connect(on_inventory_changed)
	
	# Начальная настройка
	clear_inventory()
	update_quick_slot_selection()
	set_equip_colors()
	set_slot_types()

# Обработка ввода
func _input(event: InputEvent) -> void:
	# Обработка горячих клавиш быстрых слотов (1-0)
	handle_quick_slot_input(event)
	
	# Снятие экипировки по Enter
	if event.is_action_pressed("ui_accept"):
		unequip_selected_slot()
	
	# Прокрутка колесом мыши для выбора быстрого слота
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			selected_quick_slot = max(-1, selected_quick_slot - 1)
			if selected_quick_slot < -1:
				selected_quick_slot = quick_slots.size() - 1
			update_quick_slot_selection()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			selected_quick_slot = min(quick_slots.size() - 1, selected_quick_slot + 1)
			update_quick_slot_selection()

# Инициализация слотов инвентаря
func initialize_inventory_slots() -> void:
	var slots = get_children()
	for i in data.inventory_slots().size():
		var slot = slots[i] as InventorySlotUI
		inventory_slots_ui.append(slot)

# Установка типов слотов экипировки
func set_slot_types() -> void:
	head_slot.slot_type = InventorySlotUI.ItemType.HEAD
	body_slot.slot_type = InventorySlotUI.ItemType.BODY
	weapon_slot.slot_type = InventorySlotUI.ItemType.WEAPON
	boots_slot.slot_type = InventorySlotUI.ItemType.BOOTS
	pants_slot.slot_type = InventorySlotUI.ItemType.PANTS
	accessory_slot.slot_type = InventorySlotUI.ItemType.ACCESSORY
	accessory2_slot.slot_type = InventorySlotUI.ItemType.ACCESSORY
	accessory3_slot.slot_type = InventorySlotUI.ItemType.ACCESSORY

# Установка цветов слотов экипировки
func set_equip_colors() -> void:
	head_slot.modulate = equip_colors["head"]
	body_slot.modulate = equip_colors["body"]
	pants_slot.modulate = equip_colors["pants"]
	boots_slot.modulate = equip_colors["boots"]
	weapon_slot.modulate = equip_colors["weapon"]
	accessory_slot.modulate = equip_colors["accessory"]
	accessory2_slot.modulate = equip_colors["accessory2"]
	accessory3_slot.modulate = equip_colors["accessory3"]

# Очистка всех слотов инвентаря
func clear_inventory() -> void:
	for slot in inventory_slots_ui:
		slot.set_slot_data(null)

# Обновление визуального состояния инвентаря
func update_inventory(apply_focus: bool = true) -> void:
	clear_inventory()
	update_inventory_slots()
	update_equipment_slots()
	update_quick_slots()
	
	if apply_focus and inventory_slots_ui.size() > 0:
		inventory_slots_ui[0].grab_focus()
	update_quick_slot_selection()

# Обновление основных слотов инвентаря
func update_inventory_slots() -> void:
	var inventory_slots: Array[SlotData] = data.inventory_slots()
	for i in inventory_slots.size():
		inventory_slots_ui[i].set_slot_data(inventory_slots[i])
		connect_item_signals(inventory_slots_ui[i])

# Обновление слотов экипировки
func update_equipment_slots() -> void:
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

# Обновление быстрых слотов
func update_quick_slots() -> void:
	var q_slots: Array[SlotData] = data.quick_slots()
	for i in quick_slots.size():
		quick_slots[i].set_slot_data(q_slots[i])
		connect_item_signals(quick_slots[i])

# Снятие предмета с экипированного слота
func unequip_selected_slot() -> void:
	var focused_slot = get_focused_equipment_slot()
	if focused_slot and focused_slot.slot_data:
		var slot_index = get_slot_global_index(focused_slot)
		if slot_index != -1:
			data.unequip_item(slot_index)
			update_inventory(false)

# Получение экипированного слота в фокусе
func get_focused_equipment_slot() -> InventorySlotUI:
	var equipment_slots = [head_slot, body_slot, pants_slot, boots_slot, 
						  weapon_slot, accessory_slot, accessory2_slot, accessory3_slot]
	for slot in equipment_slots:
		if slot.has_focus():
			return slot
	return null

# Обработка ввода для быстрых слотов
func handle_quick_slot_input(event: InputEvent) -> void:
	for i in range(10):
		if event.is_action_pressed("quick_slot" + str(i + 1)):
			if selected_quick_slot == i:
				data.use_quick_slot(i)
				update_quick_slot_selection()
			else:
				selected_quick_slot = i
				update_quick_slot_selection()
			return

# Обновление при изменении инвентаря
func on_inventory_changed() -> void:
	update_inventory(false)

# Подключение сигналов для слота
func connect_item_signals(item: InventorySlotUI) -> void:
	if not item.button_up.is_connected(_on_item_drop.bind(item)):
		item.button_up.connect(_on_item_drop.bind(item))
	if not item.mouse_entered.is_connected(_on_item_mouse_entered.bind(item)):
		item.mouse_entered.connect(_on_item_mouse_entered.bind(item))
	if not item.mouse_exited.is_connected(_on_item_mouse_exited):
		item.mouse_exited.connect(_on_item_mouse_exited)

# Обработка перетаскивания предметов
func _on_item_drop(item: InventorySlotUI) -> void:
	if item == null or item.slot_data == null:
		return

	var source_index = get_slot_global_index(item)
	if source_index == -1:
		return

	# Если есть целевой слот и он отличается от исходного
	if hovered_item != null and hovered_item != item:
		var target_index = get_slot_global_index(hovered_item)
		if target_index != -1:
			var source_data = data.get_slot(source_index)
			# Проверка совместимости типа с целевым слотом
			if hovered_item.slot_type != -1 and source_data.item_data.type != hovered_item.slot_type:
				return
			# Выполняем обмен
			data.swap_item_by_index(source_index, target_index)
			update_inventory(false)
			return

	# Если это слот экипировки и нет валидного целевого слота, снимаем предмет
	var equipment_start = data.slots.size() - data.equipment_slot_count - data.quick_slot_count
	var equipment_end = equipment_start + data.equipment_slot_count
	if source_index >= equipment_start and source_index < equipment_end:
		data.unequip_item(source_index)
		update_inventory(false)

# Обработчики событий мыши
func _on_item_mouse_entered(item: InventorySlotUI) -> void:
	hovered_item = item

func _on_item_mouse_exited() -> void:
	hovered_item = null

# Получение глобального индекса слота
func get_slot_global_index(slot: InventorySlotUI) -> int:
	var inv_index = inventory_slots_ui.find(slot)
	if inv_index != -1:
		return inv_index
	
	var equipment_start = data.slots.size() - data.equipment_slot_count - data.quick_slot_count
	var equipment_map = {
		head_slot: equipment_start + 0,
		body_slot: equipment_start + 2,
		pants_slot: equipment_start + 4,
		boots_slot: equipment_start + 6,
		weapon_slot: equipment_start + 1,
		accessory_slot: equipment_start + 3,
		accessory2_slot: equipment_start + 5,
		accessory3_slot: equipment_start + 7
	}
	if slot in equipment_map:
		return equipment_map[slot]
	
	var quick_start = data.slots.size() - data.quick_slot_count
	var quick_index = quick_slots.find(slot)
	if quick_index != -1:
		return quick_start + quick_index
	
	print("Slot not found: ", slot)
	return -1

# Обновление визуального выделения быстрого слота
func update_quick_slot_selection() -> void:
	for i in quick_slots.size():
		quick_slots[i].modulate = Color(1, 1, 0, 1) if i == selected_quick_slot else Color(1, 1, 1, 1)

# Получение индекса выбранного быстрого слота
func get_selected_quick_slot() -> int:
	return selected_quick_slot
