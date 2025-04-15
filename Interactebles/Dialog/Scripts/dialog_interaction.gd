@tool
@icon("res://GUI/Dialog/Icons/chat_bubbles.svg")
class_name DialogInteraction extends Area2D

signal player_interacted
signal finished

@export var enabled: bool = true

var dialog_items: Array[DialogItem]

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	if Engine.is_editor_hint():
		return
	
	area_entered.connect(_on_area_enter)
	area_exited.connect(_on_area_exit)
	
	for child in get_children():
		if child is DialogItem:
			dialog_items.append(child)

func player_interact() -> void:
	player_interacted.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	
	var filtered_items: Array[DialogItem] = []
	for item in dialog_items:
		if item.quest_id:
			var quest = GlobalQuestManager.instance.get_quest(item.quest_id)
			match item.quest_action:
				item.QuestAction.START_QUEST:
					if not GlobalQuestManager.instance.can_start_quest(item.quest_id):
						continue
				item.QuestAction.COMPLETE_QUEST:
					if not quest or quest.status != QuestResource.QuestStatus.IN_PROGRESS:
						continue
		filtered_items.append(item)
	
	if filtered_items.size() > 0:
		DialogSystem.show_dialog(filtered_items)
		DialogSystem.finished.connect(_on_dialog_finished)

func _on_area_enter(_area: Area2D) -> void:
	if enabled == false || dialog_items.size() == 0:
		return
	
	animation_player.play("show")
	PlayerManager.interact_pressed.connect(player_interact)
	pass

func _on_area_exit(_area: Area2D) -> void:
	animation_player.play("hide")
	PlayerManager.interact_pressed.disconnect(player_interact)
	pass

func _on_dialog_finished() -> void:
	DialogSystem.finished.disconnect(player_interact)
	finished.emit()

func _check_configuration_warnings() -> PackedStringArray:
	if !_check_for_dialog_items():
		return ["Requires at leasts one DialogItem node."]
	return []
	pass
	
func _check_for_dialog_items() -> bool:
	for child in get_children():
		if child is DialogItem:
			return true
	return false 
