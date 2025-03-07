@tool
@icon("res://GUI/Dialog/Icons/star_bubble.svg")
class_name DialogSystemNode extends CanvasLayer

signal finished
signal letter_added(letter: String)

var is_active: bool = false
var text_in_progress: bool = false
var wainting_for_choise: bool = false

var text_speed: float = 0.02
var text_length: int = 0
var plain_text: String

var dialog_items: Array[DialogItem]
var dialog_item_index: int = 0

@onready var dialog_ui: Control = $DialogUI
@onready var content: RichTextLabel = $DialogUI/PanelContainer/RichTextLabel
@onready var name_label: Label = $DialogUI/NameLabel 
@onready var portrait_sprite: DialogPortrait = $DialogUI/PortraitSprite
@onready var dialog_progress_indicator: PanelContainer = $DialogUI/DialogProgressIndicator
@onready var label: Label = $DialogUI/DialogProgressIndicator/Label
@onready var timer: Timer = $DialogUI/Timer
@onready var audio: AudioStreamPlayer = $DialogUI/AudioStreamPlayer
@onready var choise_options: VBoxContainer = $DialogUI/VBoxContainer

func _ready():
	if Engine.is_editor_hint():
		if get_viewport() is Window:
			get_parent().remove_child(self)
			return
		return
	timer.timeout.connect(_on_timer_timeout)
	hide_dialog()

func _unhandled_input(event):
	if !is_active:
		return
	if (
		event.is_action_pressed("interact") or
		event.is_action_pressed("attack") or
		event.is_action_pressed("ui_accept")
	):
		if text_in_progress == true:
			content.visible_characters = text_length
			timer.stop()
			text_in_progress = false
			show_dialog_button_indicator(true)
			return
		elif wainting_for_choise:
			return
		dialog_item_index += 1
		if dialog_item_index < dialog_items.size():
			start_dialog()
		else:
			hide_dialog()

func show_dialog(_items: Array[DialogItem]) -> void:
	is_active = true
	dialog_ui.visible = true
	dialog_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	dialog_items = _items
	dialog_item_index = 0
	get_tree().paused = true
	await get_tree().process_frame
	start_dialog()
	pass
	
func hide_dialog() -> void:
	is_active = false
	dialog_ui.visible = false
	choise_options.visible = false
	dialog_ui.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = false
	finished.emit()
	pass

func start_dialog() -> void:
	wainting_for_choise = false
	show_dialog_button_indicator(false)
	var _data: DialogItem = dialog_items[dialog_item_index]	
	
	if _data is DialogText:
		set_dialog_text(_data as DialogText)
	if _data is DialogChoise:
		set_dialog_choise(_data as DialogChoise)
	
func set_dialog_text(_data: DialogText) -> void:
	content.text = _data.text
	choise_options.visible = false
	name_label.text = _data.npc_info.npc_name
	portrait_sprite.texture = _data.npc_info.portrait
	portrait_sprite.audio_pitch_base = _data.npc_info.dialog_audio_pitch
	content.visible_characters = 0 
	text_length = content.get_total_character_count()
	plain_text = content.get_parsed_text()
	text_in_progress = true
	start_timer()

func set_dialog_choise(_data: DialogChoise) -> void:
	choise_options.visible = true
	wainting_for_choise = true
	for child in choise_options.get_children():
		child.queue_free()
		
	for i in _data.dialog_branches.size():
		var _new_choise: Button = Button.new()
		_new_choise.text = _data.dialog_branches[i].text
		_new_choise.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_new_choise.pressed.connect(_dialog_choice_selected.bind(_data.dialog_branches[i]))
		choise_options.add_child(_new_choise)
	
	if Engine.is_editor_hint():
		return	
	await get_tree().process_frame
	choise_options.get_child(0).grab_focus()
		
		
func _dialog_choice_selected(_data: DialogBranch) -> void:
	choise_options.visible = false
	show_dialog(_data.dialog_items)
	pass
		
func show_dialog_button_indicator(_is_visible: bool) -> void:
	dialog_progress_indicator.visible = _is_visible
	if dialog_item_index + 1 < dialog_items.size():
		label.text = "NEXT"
	else:
		label.text = "END"
	pass	

func start_timer() -> void:
	timer.wait_time = text_speed
	var _char = plain_text[ content.visible_characters - 1 ]
	if '.!?:;'.contains( _char ):
		timer.wait_time *= 4
	elif ', '.contains( _char ):
		timer.wait_time *= 2
	timer.start()


func _on_timer_timeout() -> void:
	content.visible_characters += 1
	if content.visible_characters <= text_length:	
		letter_added.emit(plain_text[content.visible_characters - 1])
		start_timer()
	else:
		show_dialog_button_indicator(true)
		text_in_progress = false
