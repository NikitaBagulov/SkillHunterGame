class_name DeathScreen extends CanvasLayer

@onready var timer_label: Label = $MarginContainer/VBoxContainer/TimerLabel
var respawn_timer: float = 5
var time_left: float = respawn_timer

func _ready():
	visible = false
	time_left = respawn_timer
	timer_label.text = "%.1f секунд" % time_left

func _process(delta: float):
	if visible:
		time_left -= delta
		timer_label.text = "%.1f секунд" % max(0, time_left)
		
		if time_left <= 0:
			queue_free()
