@tool
extends Node2D
class_name ItemPickup

# --- Настройки ---
## Данные предмета, связанные с этим пикапом
@export var item_data: ItemData: set = _set_item_data

# --- Ссылки на узлы ---
@onready var area_2d: Area2D = $Area2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

# --- Инициализация ---
func _ready() -> void:
	_update_texture()
	if Engine.is_editor_hint():
		return  # Прерываем выполнение в редакторе
	area_2d.body_entered.connect(_on_body_entered)

# --- Обработчики событий ---
## Обрабатывает столкновение с телом (игроком)
func _on_body_entered(body: Node2D) -> void:
	if body is Player and item_data:
		if PlayerManager.INVENTORY_DATA.add_item(item_data):
			_item_picked_up()

# --- Управление сбором предмета ---
## Выполняет действия при поднятии предмета
func _item_picked_up() -> void:
	area_2d.body_entered.disconnect(_on_body_entered)
	audio_stream_player_2d.play()
	visible = false
	await audio_stream_player_2d.finished
	queue_free()

# --- Управление данными предмета ---
## Устанавливает новые данные предмета и обновляет текстуру
func _set_item_data(value: ItemData) -> void:
	item_data = value
	_update_texture()

## Обновляет текстуру спрайта на основе данных предмета
func _update_texture() -> void:
	if item_data and sprite_2d:
		sprite_2d.texture = item_data.texture
