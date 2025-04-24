@tool
class_name PatrolLocation extends Node2D

signal transform_changed

@export var wait_time: float = 0.0:
	set(v):
		wait_time = v
		_update_wait_time_label()

var target_position: Vector2 = Vector2.ZERO

func _enter_tree():
	set_notify_transform(true)

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		transform_changed.emit()

func _ready():
	target_position = global_position
	_update_wait_time_label()
	if Engine.is_editor_hint():
		return
	$Sprite2D.queue_free()

func update_label(_text: String) -> void:
	$Sprite2D/Label.text = _text

func update_line(next_location: Vector2) -> void:
	var line: Line2D = $Sprite2D/Line2D
	line.points[1] = next_location - position
		
func _update_wait_time_label() -> void:
	if Engine.is_editor_hint():
		var label = $Sprite2D/Label2 as Label
		if label:
			label.text = "wait: " + str(snappedf(wait_time, 0.1)) + "s"
