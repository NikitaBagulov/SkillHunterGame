extends CanvasLayer

signal hidden
signal showen

@onready var background: ColorRect = $ColorRect
@onready var item_description: Label = $ItemDescription
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var stats_ui: StatsUI = $StatsUI
@onready var main_inventory: PanelContainer = $PanelContainer
@onready var equip_slots: PanelContainer = $PanelContainer2


var is_paused: bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	hide_inventory()
	pass # Replace with function body.

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if is_paused == false:
			show_inventory()
		else:
			hide_inventory()
		get_viewport().set_input_as_handled()
		
func show_inventory() -> void:

	#get_tree().paused = true
	stats_ui.visible = true
	background.visible = true
	item_description.visible = true
	main_inventory.visible = true
	equip_slots.visible = true
	Hud.visible = false
	is_paused = true
	showen.emit()

func hide_inventory() -> void:
	#get_tree().paused = false
	stats_ui.visible = false
	background.visible = false
	item_description.visible = false
	main_inventory.visible = false
	equip_slots.visible = false
	Hud.visible = false
	is_paused = false
	hidden.emit()

func update_item_description(new_text: String) -> void:
	item_description.text = new_text
	
func play_audio(audio: AudioStream) -> void:
	audio_stream_player.stream = audio
	audio_stream_player.play()
