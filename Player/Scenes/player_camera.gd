class_name PlayerCamera extends Camera2D

var target: Node2D  # Цель, за которой следует камера (игрок)

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
