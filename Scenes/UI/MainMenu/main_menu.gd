# MainMenu.gd
extends CanvasLayer

func _ready():
	# Подключаем сигналы кнопок
	$Panel/VBoxContainer/StartButton.connect("pressed", Callable(self._on_start_button_pressed))
	$Panel/VBoxContainer/SettingsButton.connect("pressed", Callable(self._on_settings_button_pressed))
	$Panel/VBoxContainer/ExitButton.connect("pressed", Callable(self._on_exit_button_pressed))

func _on_start_button_pressed():
	# Переход к игре
	get_tree().change_scene_to_file("res://Scenes/world.tscn")

func _on_settings_button_pressed():
	var settings_menu = load("res://Scenes/UI/SettingsMenu/settings_menu.tscn").instantiate()
	settings_menu.previous_scene_path = get_tree().current_scene.scene_file_path  # Сохраняем путь к текущей сцене
	get_tree().root.add_child(settings_menu)

func _on_exit_button_pressed():
	# Выход из игры
	get_tree().quit()
