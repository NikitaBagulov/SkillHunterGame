# StatsUI.gd
extends PanelContainer
class_name StatsUI

@onready var level_label: Label = $VBoxContainer/LevelLabel
@onready var hp_bar: ProgressBar = $VBoxContainer/HPBar
@onready var hp_label: Label = $VBoxContainer/HPBar/HPLabel
@onready var exp_bar: ProgressBar = $VBoxContainer/ExpBar
@onready var exp_label: Label = $VBoxContainer/ExpBar/ExpLabel
@onready var damage_label: Label = $VBoxContainer/DamageLabel

func _ready():
	PlayerManager.PLAYER_STATS.damage_updated.connect(update_damage_label)
	PlayerManager.PLAYER_STATS.health_updated.connect(update_hp_label)
	PlayerManager.PLAYER_STATS.player_level_up.connect(update_stats)

func update_damage_label(value: int):
	damage_label.text = "Урон: " + str(value)
	
func update_hp_label(hp: int, max_hp: int):
	print("HP: ", hp, max_hp)
	hp_label.text = "%d/%d HP" % [hp, max_hp]

func update_stats(stats: Stats) -> void:
	level_label.text = "Level: %d" % stats.level
	hp_bar.max_value = stats.max_hp
	hp_bar.value = stats.hp
	hp_label.text = "%d HP" % stats.hp
	exp_bar.max_value = stats.exp_to_next_level
	exp_label.text = "%d EXP" % stats.experience
	exp_bar.value = stats.experience
