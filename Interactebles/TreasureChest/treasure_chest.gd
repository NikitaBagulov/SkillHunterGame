@tool

class_name TreasureChest extends Node2D



@export var loot_table: Array[LootItemResource]

var is_open: bool = false

@onready var sprite: Sprite2D = $ItemSprite
@onready var label: Label = $ItemSprite/Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interact_area: Area2D = $Area2D

func _ready():
	if Engine.is_editor_hint():
		return
	interact_area.area_entered.connect(_on_area_enter)
	interact_area.area_exited.connect(_on_area_exit)
	set_chest_state()

func player_interact() -> void:
	if is_open:
		return
	
	is_open = true
	#animation_player.play("open_chest")  # Анимация открытия сундука
	#await animation_player.animation_finished  # Ждём завершения анимации открытия
	#
	if not loot_table.is_empty():
		var dropped_items = _drop_items_from_loot_table()
		if dropped_items.size() > 0:
			for item in dropped_items:
				# Устанавливаем текстуру предмета для спрайта
				if item.item_data and item.item_data.texture:
					sprite.texture = item.item_data.texture
				else:
					sprite.texture = null
				
				# Проигрываем анимацию для текущего предмета
				animation_player.play("open_chest")
				await animation_player.animation_finished  # Ждём завершения анимации предмета
				
				# Добавляем предмет в инвентарь игрока
				PlayerManager.INVENTORY_DATA.add_item(item.item_data, randi_range(item.min_quantity, item.max_quantity))
	animation_player.play("opened")
	is_open = true
# Пример функции для получения предметов из таблицы лута
func _drop_items_from_loot_table() -> Array:
	var selected_items = _select_item_from_loot_table()
	return selected_items
	
func _select_item_from_loot_table() -> Array:
	var dropped_items = []
	for loot_item in loot_table:
		if randf() < loot_item.chance:
			dropped_items.append(loot_item)
	return dropped_items

func _on_area_enter(_area: Area2D) -> void:
	PlayerManager.interact_pressed.connect(player_interact)

func _on_area_exit(_area: Area2D) -> void:
	PlayerManager.interact_pressed.disconnect(player_interact)

func set_chest_state() -> void:
	if is_open:
		animation_player.play("opened")
	else:
		animation_player.play("closed")
