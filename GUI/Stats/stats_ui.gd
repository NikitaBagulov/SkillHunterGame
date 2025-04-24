# StatsUI.gd
extends PanelContainer
class_name StatsUI

@onready var level_label: Label = $VBoxContainer/LevelLabel
@onready var hp_bar: TextureProgressBar = $VBoxContainer/HPBar
@onready var hp_label: Label = $VBoxContainer/HPBar/HPLabel
@onready var exp_bar: TextureProgressBar = $VBoxContainer/ExpBar
@onready var exp_label: Label = $VBoxContainer/ExpBar/ExpLabel
@onready var damage_label: Label = $VBoxContainer/DamageLabel
@onready var currency_label: Label = $VBoxContainer/CurrencyLabel


func _ready():
	connect_updating_ui()
	update_damage_label(PlayerManager.PLAYER_STATS.total_damage)
	update_hp_label(PlayerManager.PLAYER_STATS.hp, PlayerManager.PLAYER_STATS.max_hp)
	update_currency_label(PlayerManager.PLAYER_STATS.currency)
	update_stats(PlayerManager.PLAYER_STATS)

func connect_updating_ui():
	PlayerManager.PLAYER_STATS.experience_updated.connect(update_stats)
	PlayerManager.PLAYER_STATS.damage_updated.connect(update_damage_label)
	PlayerManager.PLAYER_STATS.health_updated.connect(update_hp_label)
	PlayerManager.PLAYER_STATS.player_level_up.connect(update_stats)
	PlayerManager.PLAYER_STATS.currency_updated.connect(update_currency_label)

func update_damage_label(value: int):
	#print("Урон ", value)
	damage_label.text = "Урон: " + str(value)
	
func update_hp_label(hp: int, max_hp: int):
	##print("HP ", hp, max_hp)
	hp_bar.max_value = max_hp
	hp_bar.value = hp

	hp_label.text = "%d/%d HP" % [hp, max_hp]

func update_stats(stats: Stats) -> void:
	level_label.text = "Level: %d" % stats.level
	exp_bar.max_value = stats.exp_to_next_level
	exp_label.text = "%d EXP" % stats.experience
	exp_bar.value = stats.experience
	
func update_currency_label(currency: int):
	currency_label.text = "%d 💎" % currency
