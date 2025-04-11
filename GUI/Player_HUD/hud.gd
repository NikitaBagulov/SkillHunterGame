extends CanvasLayer

var hearts: Array[HeartGUI] = []

@onready var hp_label: Label = $VBoxContainer/HPBar/HPLabel
@onready var hp_bar: ProgressBar = $VBoxContainer/HPBar
func _ready():
	PlayerManager.PLAYER_STATS.health_updated.connect(update_hp)
	#for child in $Control/HFlowContainer.get_children():
		#if child is HeartGUI:
			#hearts.append(child)
			#child.visible = false
	#pass

func update_hp(_hp: int, _max_hp: int) -> void:
	hp_bar.max_value = _max_hp
	hp_bar.value = _hp
	hp_label.text = "%d/%d HP" % [_hp, _max_hp]
	#update_max_hp(_max_hp)
	#for i in _max_hp:
		#update_heart(i, _hp)
		#pass
	#pass
	
#func update_heart(_index: int, _hp: int) -> void:
	#var _value: int = clampi(_hp - _index * 2, 0, 2)
	#hearts[_index].value = _value
	#pass
	#
#func update_max_hp(_max_hp: int) -> void:
	#var _heart_count: int = roundi(_max_hp * 0.5)
	#for i in hearts.size():
		#if i < _heart_count:
			#hearts[i].visible = true
		#else:
			#hearts[i].visible = false
	#pass
