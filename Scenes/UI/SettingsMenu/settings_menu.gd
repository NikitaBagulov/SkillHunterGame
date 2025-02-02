# SettingsMenu.gd
extends CanvasLayer

@export var resolutions: Array[Vector2] = [
	Vector2(1280, 720),  # 720p
	Vector2(1920, 1080),  # 1080p
	Vector2(2560, 1440)  # 1440p
]

var previous_scene_path: String  # Переменная для хранения пути к предыдущей сцене

func _ready():
	# Подключаем сигналы элементов
	$Panel/VBoxContainer/FullscreenCheckButton.connect("toggled", Callable(self._on_fullscreen_toggled))
	$Panel/VBoxContainer/ResolutionOptionButton.connect("item_selected", Callable(self._on_resolution_selected))
	$Panel/VBoxContainer/BackButton.connect("pressed", Callable(self._on_back_button_pressed))

	# Заполняем OptionButton доступными разрешениями
	for resolution in resolutions:
		$Panel/VBoxContainer/ResolutionOptionButton.add_item("%dx%d" % [resolution.x, resolution.y])

func _on_fullscreen_toggled(button_pressed: bool):
	# Переключение полноэкранного режима
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_resolution_selected(index: int):
	# Установка выбранного разрешения
	var selected_resolution = resolutions[index]
	DisplayServer.window_set_size(selected_resolution)

func _on_back_button_pressed():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1)  # Плавное уменьшение прозрачности
	tween.tween_callback(queue_free)
