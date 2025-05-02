# MarketSystem.gd
class_name MarketSystem extends Node

signal finished

@onready var market_ui: MarketUI = $MarketUi

var is_market_open: bool = false

func _ready():
	market_ui.visible = false

	market_ui.transaction_completed.connect(_on_transaction_completed)
	market_ui.close_requested.connect(_on_close_requested)

func show_market(items: Array[ItemData]) -> void:
	market_ui.inventory_data = PlayerManager.INVENTORY_DATA
	if is_market_open:
		return
	is_market_open = true
	market_ui.set_market_items(items)
	market_ui.visible = true
	
	get_tree().paused = true
	PlayerManager.INVENTORY_DATA.data_changed.connect(market_ui.update_inventory)

func hide_market() -> void:
	market_ui.inventory_data = PlayerManager.INVENTORY_DATA
	if not is_market_open:
		return
	is_market_open = false
	market_ui.visible = false
	get_tree().paused = false
	PlayerManager.INVENTORY_DATA.data_changed.disconnect(market_ui.update_inventory)
	finished.emit()

func _on_transaction_completed() -> void:
	# Обновление UI происходит через сигналы инвентаря
	pass

func _on_close_requested() -> void:
	hide_market()
