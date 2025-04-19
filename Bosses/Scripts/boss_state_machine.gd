extends Node
class_name BossStateMachine

# --- Переменные ---
## Список всех состояний врага
var states: Array[BossState] = []
## Предыдущее состояние
var previous_state: BossState = null
## Текущее состояние
var current_state: BossState = null

# --- Инициализация ---
func _ready() -> void:
	process_mode = PROCESS_MODE_DISABLED

func initialize(boss: Boss) -> void:
	# Собираем все состояния из дочерних узлов
	for child in get_children():
		if child is BossState:
			states.append(child)
	
	# Инициализируем состояния
	for state in states:
		state.boss = boss
		state.state_machine = self
		state.init()
	
	# Активируем первое состояние, если есть
	if not states.is_empty():
		change_state(states[0])
		process_mode = PROCESS_MODE_INHERIT

# --- Обработка ---
func _process(delta: float) -> void:
	var new_state = current_state.process(delta)
	change_state(new_state)

func _physics_process(delta: float) -> void:
	var new_state = current_state.physics(delta)
	change_state(new_state)

# --- Управление состояниями ---
## Переключает текущее состояние на новое
func change_state(new_state: BossState) -> void:
	if new_state == null or new_state == current_state:
		return
	
	if current_state:
		current_state.exit()
	
	previous_state = current_state
	current_state = new_state
	current_state.enter()
