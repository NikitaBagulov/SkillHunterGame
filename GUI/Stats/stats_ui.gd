# StatsUI.gd
extends PanelContainer
class_name StatsUI

@onready var level_label: Label = $VBoxContainer/LevelLabel
@onready var hp_bar: ProgressBar = $VBoxContainer/HPBar
@onready var exp_bar: ProgressBar = $VBoxContainer/ExpBar
@onready var damage_label: Label = $VBoxContainer/DamageLabel

func _ready():
	PlayerManager.PLAYER_STATS.damage_updated.connect(update_damage_label)

func update_damage_label(value: int):
	damage_label.text = "Урон: " + str(value)

func update_stats(stats: Stats) -> void:
	level_label.text = "Level: %d" % stats.level
	hp_bar.max_value = stats.max_hp
	hp_bar.value = stats.hp
	exp_bar.max_value = stats.exp_to_next_level
	exp_bar.value = stats.experience
