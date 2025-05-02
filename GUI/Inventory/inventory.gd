extends CanvasLayer

signal hidden
signal showen

@onready var background: ColorRect = $TabContainer/ColorRect
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var stats_ui: StatsUI = $TabContainer/MarginContainer/InventoryContainer/HBoxContainer/StatsUI
@onready var inventory_ui = $TabContainer/MarginContainer/InventoryContainer/HBoxContainer/PanelContainer/VBoxContainer/GridContainer
@onready var skill_forge_ui: SkillForgeUI = $TabContainer/MarginContainer/InventoryContainer/HBoxContainer/VBoxContainer/SkillForgeUI

var selected_quick_slot: InventorySlotUI = null
var is_paused: bool = false

var stored_states: Dictionary = {}  # Хранит исходное состояние видимости CanvasLayer

func _ready():
	hide_inventory()
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
	stats_ui.connect_updating_ui()
	visible = true
	Hud.visible = false
	is_paused = true
	showen.emit()

func hide_inventory() -> void:
	visible = false
	Hud.visible = true
	is_paused = false
	hidden.emit()
	
func play_audio(audio: AudioStream) -> void:
	audio_stream_player.stream = audio
	audio_stream_player.play()
