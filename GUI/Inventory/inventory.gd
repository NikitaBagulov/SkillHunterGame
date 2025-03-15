extends CanvasLayer

signal hidden
signal showen

@onready var item_description: Label = $ItemDescription
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var stats_ui: StatsUI = $StatsUI

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
	visible = true
	is_paused = true
	showen.emit()

func hide_inventory() -> void:
	#get_tree().paused = false
	stats_ui.visible = false
	visible = false
	is_paused = false
	hidden.emit()

func update_item_description(new_text: String) -> void:
	item_description.text = new_text
	
func play_audio(audio: AudioStream) -> void:
	audio_stream_player.stream = audio
	audio_stream_player.play()
