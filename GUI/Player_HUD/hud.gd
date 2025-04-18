extends CanvasLayer

var hearts: Array[HeartGUI] = []

@onready var hp_label: Label = $VBoxContainer/VBoxContainer/HPBar/HPLabel
@onready var hp_bar: ProgressBar = $VBoxContainer/VBoxContainer/HPBar
@onready var currency_label: Label = $VBoxContainer/VBoxContainer/CurrencyLabel


func _ready():
	update_hp(PlayerManager.PLAYER_STATS.hp, PlayerManager.PLAYER_STATS.max_hp)
	update_currency(PlayerManager.PLAYER_STATS.currency)
	PlayerManager.PLAYER_STATS.health_updated.connect(update_hp)
	PlayerManager.PLAYER_STATS.currency_updated.connect(update_currency)

func update_hp(_hp: int, _max_hp: int) -> void:
	hp_bar.max_value = _max_hp
	hp_bar.value = _hp
	hp_label.text = "%d/%d HP" % [_hp, _max_hp]
	
func update_currency(currency: int):
	currency_label.text = "%d 💎" % currency
