@tool
@icon("res://GUI/Market/Icons/market_stall.svg")
class_name MarketInteraction extends Area2D

signal player_interacted
signal finished

@export var enabled: bool = true
@export var market_items: Array[ItemData] = []  # Предметы, доступные в магазине

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	if Engine.is_editor_hint():
		return
	
	area_entered.connect(_on_area_enter)
	area_exited.connect(_on_area_exit)

func player_interact() -> void:
	player_interacted.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	Market.show_market(market_items)
	Market.finished.connect(_on_market_finished)

func _on_area_enter(_area: Area2D) -> void:
	if enabled == false || market_items.size() == 0:
		return
	
	animation_player.play("show")
	PlayerManager.interact_pressed.connect(player_interact)

func _on_area_exit(_area: Area2D) -> void:
	if enabled == false || market_items.size() == 0:
		return
	animation_player.play("hide")
	PlayerManager.interact_pressed.disconnect(player_interact)

func _on_market_finished() -> void:
	Market.finished.disconnect(_on_market_finished)
	finished.emit()

func _check_configuration_warnings() -> PackedStringArray:
	if market_items.size() == 0:
		return ["Requires at least one ItemData in market_items."]
	return []
