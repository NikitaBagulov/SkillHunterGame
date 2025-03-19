extends Area2D
class_name ItemMagnet

# --- Настройки ---
## Сила притяжения магнита (влияет на ускорение предметов)
@export var magnet_strength: float = 1.0
## Воспроизводить ли звук при притягивании предмета
@export var play_magnet_audio: bool = false

# --- Переменные ---
## Список притягиваемых предметов
var items: Array[ItemPickup] = []
## Скорости притягивания для каждого предмета
var speeds: Array[float] = []

# --- Ссылки на узлы ---
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

# --- Инициализация ---
func _ready() -> void:
	area_entered.connect(_on_area_entered)

# --- Обработка каждого кадра ---
func _process(delta: float) -> void:
	# Обратный цикл для безопасного удаления элементов
	for i in range(items.size() - 1, -1, -1):
		var item = items[i]
		if not is_instance_valid(item):
			# Удаляем недействительный предмет
			items.remove_at(i)
			speeds.remove_at(i)
			continue
		
		var distance = item.global_position.distance_to(global_position)
		if distance > speeds[i]:
			# Увеличиваем скорость притягивания и двигаем предмет
			speeds[i] += magnet_strength * delta
			item.position += item.global_position.direction_to(global_position) * speeds[i]
		else:
			# Предмет достиг магнита
			item.global_position = global_position

# --- Обработчики событий ---
## Добавляет новый предмет в список притягиваемых
func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent is ItemPickup:
		var new_item = parent as ItemPickup
		items.append(new_item)
		speeds.append(magnet_strength)
		if play_magnet_audio:
			audio.play()
