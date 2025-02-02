# Camera.gd
extends Camera2D

@export var target: Node2D

@export var zoom_speed: float = 0.1
@export var min_zoom: Vector2 = Vector2(2, 2)
@export var max_zoom: Vector2 = Vector2(5, 5)

func _ready():
	make_current()
	position_smoothing_enabled = true
	#print("Camera initialized. Target is:", target.name if target else "null")

func _physics_process(delta: float):
	if target:
		var target_pos = target.global_position
		global_position = global_position.lerp(target_pos, delta)
		
		# Простая отладка через консоль
		#print("Camera: ", global_position, " | Target: ", target_pos)
	else:
		push_warning("Camera target is not set!")

func zoom_camera(delta_zoom: float):
	var new_zoom = zoom + Vector2.ONE * delta_zoom * zoom_speed
	new_zoom = new_zoom.clamp(min_zoom, max_zoom)
	zoom = new_zoom
