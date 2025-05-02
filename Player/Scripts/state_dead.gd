class_name State_Dead extends State

@onready var idle: State_Idle = $"../Idle"
var death_screen_scene = preload("res://GUI/DeathScreen/DeathScreen.tscn")

var death_screen_instance: DeathScreen  # Будем хранить ссылку на текущий экземпляр

const RESPAWN_DELAY = 5  # Задержка перед респавном в секундах

# --- Переменные ---
var _timer: Timer

func _ready():
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_respawn_timer_timeout)
	
	add_child(_timer)
	PlayerManager.PLAYER_STATS.player_died.connect(_on_player_died)

func enter() -> void:
	_on_respawn_timer_timeout()
	death_screen_instance = death_screen_scene.instantiate()
	get_tree().root.add_child(death_screen_instance)
	death_screen_instance.visible = true
	# Останавливаем игрока
	player.velocity = Vector2.ZERO
	player.update_animation("dead")
	
	# Делаем игрока неуязвимым и отключаем коллизии


func exit() -> void:
	if death_screen_instance and is_instance_valid(death_screen_instance):
		death_screen_instance.queue_free()

func process(delta: float) -> State:
	return null

func physics_process(delta: float) -> State:
	return null

func _on_respawn_timer_timeout() -> void:
	# Забираем 75% монет
	var lost_currency = int(PlayerManager.PLAYER_STATS.currency * 0.75)
	PlayerManager.PLAYER_STATS.currency -= lost_currency
	
	# Телепортируем игрока в хаб
	var hub_portal = get_tree().get_first_node_in_group("hub_portal")
	if hub_portal:
		hub_portal._on_body_entered(player)
	else:
		push_warning("No hub portal found in scene!")
	
	# Восстанавливаем здоровье игрока (50% от максимального)
	PlayerManager.PLAYER_STATS.hp = PlayerManager.PLAYER_STATS.max_hp / 2
	
	# Возвращаем игрока в idle состояние
	state_machine.change_state(idle)

func _on_player_died() -> void:
	# Проверяем, что state_machine инициализирован
	if state_machine:
		state_machine.change_state(self)
