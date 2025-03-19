extends Resource
class_name DropData

# --- Настройки ---
## Данные предмета для дропа
@export var item: ItemData
## Шанс выпадения предмета (0-100%)
@export_range(0, 100, 1, "suffix:%") var probability: float = 100.0
## Минимальное количество предметов
@export_range(1, 10, 1, "suffix:items") var min_amount: int = 1
## Максимальное количество предметов
@export_range(1, 10, 1, "suffix:items") var max_amount: int = 1

# --- Методы ---
## Возвращает количество предметов для дропа (0, если вероятность не сработала)
func get_drop_count() -> int:
	if randf_range(0, 100) >= probability:
		return 0
	return randi_range(min_amount, max_amount)
