class_name State_Walk extends State

@onready var idle : State = $"../Idle"
@onready var attack: State = $"../Attack"

@export var walk_sound: AudioStreamWAV

# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func enter() -> void:
	player.update_animation("walk")
	PlayerManager.play_audio(walk_sound, true)
	pass
	
func exit() -> void:
	pass
	
func process(_delta: float) -> State:
	
	if player.direction == Vector2.ZERO:
		return idle
	player.velocity = player.direction * PlayerManager.PLAYER_STATS.move_speed
	
	
	if player.set_direction():
		player.update_animation("walk")
		
	return null

func physics(_delta: float) -> State:
	return null
	
func handle_input(_event: InputEvent) -> State:
	if _event.is_action_pressed("attack") and PlayerManager.can_attack:
		return attack
	return null
