extends CanvasLayer
class_name LoadingScreen

@onready var progress_bar: ProgressBar = $HBoxContainer/ProgressBar
@onready var label: Label = $HBoxContainer/Label
@onready var animation_player = $AnimationPlayer

var is_loading_complete := false  # Флаг, что загрузка завершена

func _ready():
	#hide_loading()  # Скрываем по умолчанию при запуске игры
	process_mode = PROCESS_MODE_ALWAYS
	set_process_input(false)  # Отключаем обработку ввода по умолчанию

func set_progress(value: float) -> void:
	progress_bar.value = value
	if value >= 100.0 and not is_loading_complete:
		is_loading_complete = true
		label.text = "Press ENTER to continue..."  # Меняем текст
		set_process_input(true)  # Включаем обработку ввода для ожидания клавиши

func show_loading() -> void:
	Inventory.visible = false
	visible = true
	animation_player.play("fade_in")
	is_loading_complete = false
	label.text = "Loading..."
	progress_bar.value = 0
	get_tree().set_pause(true)  # Приостанавливаем игру (блокируем ввод и физику)
	
func hide_loading() -> void:
	animation_player.play("fade_out")
	await animation_player.animation_finished
	visible = false
	Inventory.visible = false
	is_loading_complete = false
	set_process_input(false)  # Отключаем обработку ввода
	get_tree().set_pause(false)

func _input(event: InputEvent) -> void:
	if is_loading_complete and event is InputEventKey and event.pressed:
		#print(event)
		hide_loading()  # Скрываем экран при нажатии любой клавиши
