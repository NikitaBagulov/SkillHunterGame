extends CanvasLayer

signal hidden
signal showen

@onready var background: ColorRect = $ColorRect
#@onready var item_description: Label = $TabContainer/InventoryContainer/HBoxContainer/PanelContainer/VBoxContainer/ItemDescription
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var stats_ui: StatsUI = $TabContainer/InventoryContainer/HBoxContainer/VBoxContainer/HBoxContainer/StatsUI
@onready var inventory_ui = $TabContainer/InventoryContainer/HBoxContainer/PanelContainer/VBoxContainer/GridContainer
@onready var skill_forge_ui: SkillForgeUI = $TabContainer/InventoryContainer/HBoxContainer/VBoxContainer/HBoxContainer/SkillForgeUI

var selected_quick_slot: InventorySlotUI = null
var is_paused: bool = false

func _ready():
	hide_inventory()
	# Связываем InventoryUI и SkillForgeUI с данными инвентаря
	inventory_ui.data = PlayerManager.INVENTORY_DATA
	skill_forge_ui.inventory_data = PlayerManager.INVENTORY_DATA

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if is_paused == false:
			show_inventory()
		else:
			hide_inventory()
		get_viewport().set_input_as_handled()

func show_inventory() -> void:
	visible = true
	#stats_ui.visible = true
	#background.visible = true
	#item_description.visible = true
	#hbox_container.visible = true
	Hud.visible = false
	is_paused = true
	
	showen.emit()
	get_tree().paused = true

func hide_inventory() -> void:
	visible = false
	#stats_ui.visible = false
	#background.visible = false
	#item_description.visible = false
	#hbox_container.visible = false
	Hud.visible = true
	is_paused = false
	hidden.emit()
	get_tree().paused = false

#func update_item_description(new_text: String) -> void:
	#item_description.text = new_text
	
func play_audio(audio: AudioStream) -> void:
	audio_stream_player.stream = audio
	audio_stream_player.play()
