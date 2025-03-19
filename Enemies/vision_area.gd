extends Area2D
class_name VisionArea

# --- Сигналы ---
## Сигнал срабатывает, когда игрок входит в зону видимости
signal player_entered
## Сигнал срабатывает, когда игрок покидает зону видимости
signal player_exited

# --- Инициализация ---
func _ready() -> void:
	# Подключаем сигналы обнаружения тел
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Связываемся с родительским врагом, если он есть
	var parent = get_parent()
	if parent is Enemy:
		parent.direction_changed.connect(_on_direction_changed)

# --- Обработчики событий ---
## Обрабатывает вход объекта в зону видимости
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_entered.emit()

## Обрабатывает выход объекта из зоны видимости
func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_exited.emit()

## Поворачивает зону видимости в зависимости от направления врага
func _on_direction_changed(new_direction: Vector2) -> void:
	match new_direction:
		Vector2.DOWN: rotation_degrees = 0
		Vector2.UP: rotation_degrees = 180
		Vector2.LEFT: rotation_degrees = 90
		Vector2.RIGHT: rotation_degrees = -90
		_: rotation_degrees = 0  # По умолчанию вниз
