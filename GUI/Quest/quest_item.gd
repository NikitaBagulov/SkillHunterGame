class_name QuestItem extends PanelContainer

@onready var title_label: RichTextLabel = $VBoxContainer/Title
@onready var description_label: Label = $VBoxContainer/Description
@onready var objectives_container: VBoxContainer = $VBoxContainer/Objectives

func setup(quest: QuestResource) -> void:
	title_label.text = quest.title
	description_label.text = quest.description
	
	for objective in quest.objectives:
		var objective_label = Label.new()
		var status = "✔" if objective.completed else "⬜"
		objective_label.text = "- %s: %d/%d %s" % [objective.description, objective.current_value, objective.target_value, status]
		objectives_container.add_child(objective_label)

	if quest.status == QuestResource.QuestStatus.COMPLETED:
		title_label.text += " [color=green][b]Выполнено[/b][/color]"
		title_label.modulate = Color(0.7, 1.0, 0.7)  # Светло-зеленый оттенок для завершенных квестов
	else:
		title_label.modulate = Color.WHITE  # Белый для активных квестов
	
		title_label.text = quest.title
