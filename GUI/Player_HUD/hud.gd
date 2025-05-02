extends CanvasLayer

@onready var hp_label: Label = $VBoxContainer/VBoxContainer2/VBoxContainer/HPBar/HPLabel
@onready var currency_label: Label = $VBoxContainer/VBoxContainer2/VBoxContainer/CurrencyLabel
@onready var hp_bar: TextureProgressBar = $VBoxContainer/VBoxContainer2/VBoxContainer/HPBar

@onready var boss_name_label: Label = $VBoxContainer/VBoxContainer2/VBoxContainer2/BossHPContainer/BossNameLabel
@onready var boss_hp_bar: TextureProgressBar = $VBoxContainer/VBoxContainer2/VBoxContainer2/BossHPContainer/BossHPBar
@onready var boss_hp_label: Label = $VBoxContainer/VBoxContainer2/VBoxContainer2/BossHPContainer/BossHPBar/BossHPLabel
@onready var boss_hp_container: VBoxContainer = $VBoxContainer/VBoxContainer2/VBoxContainer2/BossHPContainer

@onready var quick_slot_container: GridContainer = $VBoxContainer/VBoxContainer2/VBoxContainer2/PanelContainer3/QuickSlotContainer


@onready var quick_slots_hud: Array[InventorySlotUI] = [
	%QuickSlot1, %QuickSlot2, %QuickSlot3, %QuickSlot4, %QuickSlot5,
	%QuickSlot6, %QuickSlot7, %QuickSlot8, %QuickSlot9, %QuickSlot10
]


func _ready():
	connect_stats_signals()
	boss_hp_container.visible = false
	
	EventBus.boss_activated.connect(_on_boss_activated)
	EventBus.boss_deactivated.connect(_on_boss_deactivated)
	EventBus.boss_hp_updated.connect(_on_boss_hp_updated)
	
	EventBus.quick_slots_updated.connect(update_quick_slots_hud)
	EventBus.quick_slot_selected.connect(update_quick_slot_selection)

func connect_stats_signals():
	update_hp(PlayerManager.PLAYER_STATS.hp, PlayerManager.PLAYER_STATS.max_hp)
	update_currency(PlayerManager.PLAYER_STATS.currency)
	PlayerManager.PLAYER_STATS.health_updated.connect(update_hp)
	PlayerManager.PLAYER_STATS.currency_updated.connect(update_currency)

func update_quick_slots_hud():
	var quick_slots = PlayerManager.INVENTORY_DATA.quick_slots()
	for i in quick_slots.size():
		var slot = quick_slots[i]
		var slot_ui = quick_slots_hud[i]
		
		slot_ui.set_slot_data(slot)

func update_quick_slot_selection(selected_quick_slot: int = 0) -> void:
	for i in quick_slots_hud.size():
		quick_slots_hud[i].modulate = Color(1, 1, 0, 1) if i == selected_quick_slot else Color(1, 1, 1, 1)
				
func update_hp(_hp: int, _max_hp: int) -> void:
	hp_bar.max_value = _max_hp
	hp_bar.value = _hp
	hp_label.text = "%d/%d HP" % [_hp, _max_hp]
	
func update_currency(currency: int):
	currency_label.text = "%d 💎" % currency

func _on_boss_activated(boss: Boss):
	if boss != null:
		boss_hp_container.visible = true

func _on_boss_deactivated(boss: Boss):
	if boss != null:
		boss_hp_container.visible = false

func _on_boss_hp_updated(boss: Boss, current_hp: int, max_hp: int):
	if boss != null:
		boss_name_label.text = boss.boss_name
		boss_hp_bar.max_value = max_hp
		boss_hp_bar.value = current_hp
		boss_hp_label.text = "%d/%d HP" % [current_hp, max_hp]
