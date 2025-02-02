# GameUI.gd
extends CanvasLayer

func _ready():
	# Подключаем сигналы кнопок
	
	
	$PauseButton.connect("pressed", Callable(self._on_pause_button_pressed))
	$PauseMenu/VBoxContainer/ResumeButton.connect("pressed", Callable(self._on_resume_button_pressed))
	$PauseMenu/VBoxContainer/SettingsButton.connect("pressed", Callable(self._on_settings_button_pressed))
	$PauseMenu/VBoxContainer/MainMenuButton.connect("pressed", Callable(self._on_main_menu_button_pressed))

	# Скрываем меню паузы при старте
	$PauseMenu.visible = false

func _on_pause_button_pressed():
	# Открываем меню паузы и ставим игру на паузу
	$PauseMenu.visible = true
	#get_tree().paused = true

func _on_resume_button_pressed():
	# Закрываем меню паузы и продолжаем игру
	$PauseMenu.visible = false
	get_tree().paused = false

func _on_settings_button_pressed():
	$PauseMenu.visible = false
	var settings_menu = load("res://Scenes/UI/SettingsMenu/settings_menu.tscn").instantiate()
	settings_menu.previous_scene_path = get_tree().current_scene.scene_file_path  # Сохраняем путь к текущей сцене
	get_tree().root.add_child(settings_menu)

func _on_main_menu_button_pressed():
	# Возврат в главное меню и снятие паузы
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu/main_menu.tscn")
