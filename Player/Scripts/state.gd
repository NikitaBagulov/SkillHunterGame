class_name State extends Node

static var player: Player
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func enter() -> void:
	pass
	
func exit() -> void:
	pass
	
func process(_delta: float) -> State:
	return null

func physics(_delta: float) -> State:
	return null
	
func handle_input(_event: InputEvent) -> State:
	return null
