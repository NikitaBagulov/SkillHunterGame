class_name LootItemResource extends Resource
# Определение структуры для предмета с шансом

@export var item_data: ItemData
@export var chance: float = 1  # Шанс выпадения, например, 0.3 для 30%
@export var min_quantity: int = 1  # Минимальное количество
@export var max_quantity: int = 1  # Максимальное количество
