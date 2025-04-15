class_name QuestItem extends PanelContainer

@onready var title_label: Label = $VBoxContainer/Title
@onready var description_label: Label = $VBoxContainer/Description
@onready var objectives_container: VBoxContainer = $VBoxContainer/Objectives

func setup(quest: QuestResource) -> void:
	title_label.text = quest.title
	description_label.text = quest.description
	
	for objective in quest.objectives:
		var objective_label = Label.new()
		objective_label.text = "%s: %d/%d" % [objective.description, objective.current_value, objective.target_value]
		objectives_container.add_child(objective_label)
