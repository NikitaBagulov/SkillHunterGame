extends Node2D

@export var music: AudioStream

func _ready():
	self.y_sort_enabled = true
	AudioManager.play_music(music)
