class_name ObjectData extends RefCounted

var scene_path: String
var position: Vector2

func _init(path: String, pos: Vector2):
	scene_path = path
	position = pos
