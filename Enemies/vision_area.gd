class_name VisionArea extends Area2D

signal player_entered()
signal player_exited()

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exit)
	var p = get_parent()
	if p is Enemy:
		p.direction_changed.connect(_on_direction_change)
	
func _on_body_entered(_body: Node2D) -> void:
	if _body is Player:
		player_entered.emit()
		
func _on_body_exit(_body: Node2D) -> void:
	if _body is Player:
		player_exited.emit()

func _on_direction_change(new_direction: Vector2) -> void:
	match new_direction:
		Vector2.DOWN:
			rotation_degrees = 0	
		Vector2.UP:
			rotation_degrees = 180
		Vector2.LEFT:
			rotation_degrees = 90
		Vector2.RIGHT:
			rotation_degrees = -90
		_:
			rotation_degrees = 0 
