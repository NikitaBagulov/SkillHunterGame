extends Control

@onready var start_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/StartButton
@onready var exit_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/ExitButton

func _ready():
	# Подключаем обработчики событий к кнопкам
	process_mode = Node.PROCESS_MODE_ALWAYS
	Inventory.visible = false
	Hud.visible = false
	WorldCamera.make_current()
	
	start_button.pressed.connect(_on_start_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)

func _on_start_button_pressed():
	
	await get_tree().change_scene_to_file("res://main_root.tscn")
	visible = false
	Hud.visible = true
	
	

func _on_exit_button_pressed():
	# Эмитируем сигнал о выходе из игры
	get_tree().quit()
