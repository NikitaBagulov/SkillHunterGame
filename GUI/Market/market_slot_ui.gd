class_name MarketSlotUI extends InventorySlotUI

func _ready() -> void:
	super._ready()
	modulate = Color(1, 0.8, 0.8)  # Визуальное отличие для слотов магазина
	tooltip.hide()  # Убедимся, что собственный tooltip отключен

func item_pressed() -> void:
	pass  # Предотвращаем экипировку/использование в рынке

func _on_mouse_entered() -> void:
	pass  # Отключаем tooltip InventorySlotUI

func _on_mouse_exited() -> void:
	pass  # Отключаем обработку выхода мыши
