class_name PlayerCamera extends Camera2D

var target: Node2D  # Цель, за которой следует камера (игрок)

@export var visibility_buffer: float = 100.0  # Дополнительный буфер в пикселях

func _ready():
	make_current()

func _process(delta):
	if target:
		global_position = target.global_position

func set_target(node: Node2D):
	target = node

func update_limits(bounds: Array[Vector2]) -> void:
	if bounds == [] or bounds.size() < 2:
		return
	limit_left = int(bounds[0].x)
	limit_top = int(bounds[0].y)
	limit_right = int(bounds[1].x)
	limit_bottom = int(bounds[1].y)

# Метод для получения видимой области камеры с буфером
func get_camera_bounds() -> Rect2:
	var viewport_size = get_viewport_rect().size / zoom  # Размер области в мировых координатах
	var camera_center = global_position
	var half_size = viewport_size / 2
	# Добавляем буфер к размерам видимой области
	var buffered_size = viewport_size + Vector2(visibility_buffer * 2, visibility_buffer * 2)
	var buffered_half_size = buffered_size / 2
	return Rect2(camera_center - buffered_half_size, buffered_size)

# Проверка, находится ли объект в видимой области
func is_in_view(position: Vector2) -> bool:
	return get_camera_bounds().has_point(position)
