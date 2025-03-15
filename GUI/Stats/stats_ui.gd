# StatsUI.gd
extends PanelContainer
class_name StatsUI

@onready var level_label: Label = $VBoxContainer/LevelLabel
@onready var hp_bar: ProgressBar = $VBoxContainer/HPBar
@onready var exp_bar: ProgressBar = $VBoxContainer/ExpBar

func update_stats(stats: Stats) -> void:
	print(stats.level, " ", stats.exp_to_next_level, " ",stats.experience)
	level_label.text = "Level: %d" % stats.level
	hp_bar.max_value = stats.max_hp
	hp_bar.value = stats.hp
	exp_bar.max_value = stats.exp_to_next_level
	exp_bar.value = stats.experience
