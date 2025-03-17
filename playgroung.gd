extends Node2D

@export var music: AudioStream

func _ready():
	self.y_sort_enabled = true
	AudioManager.play_music(music)
	WorldCamera.make_current()
	WorldCamera.set_target(PlayerManager.get_player())
	Hud.visible = true
