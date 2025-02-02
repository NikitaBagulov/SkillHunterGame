class_name AnimationComponent
extends Node

@export var animation_player: AnimationPlayer
@export var default_animation: String = "idle"
@export var animations: Array[AnimationConfig] = []

var current_animation: String = ""
var requested_animation: String = ""
var is_busy: bool = false

func _ready():
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)
		play(default_animation)

func add_animation(anim_name: String, priority: int, loop: bool):
	var new_config = AnimationConfig.new()
	new_config.name = anim_name
	new_config.priority = priority
	new_config.loop = loop
	animations.append(new_config)

func play(anim_name: String, force: bool = false):
	if !animation_player or !_has_animation(anim_name):
		print("Нету анимации")
		return
	
	var anim_info = _get_animation_info(anim_name)
	var current_priority = _get_current_priority()
	
	if force:
		_play_animation(anim_name)
		return
	
	if anim_info["priority"] > current_priority or current_animation == "":
		_play_animation(anim_name)
	else:
		requested_animation = anim_name

func _play_animation(anim_name: String):
	var anim_info = _get_animation_info(anim_name)
	
	if animation_player.current_animation == anim_name:
		return
	
	current_animation = anim_name
	animation_player.play(anim_name)
	
	if not anim_info["loop"]:
		is_busy = true

func _has_animation(anim_name: String) -> bool:
	for anim in animations:
		if anim.name == anim_name:
			return true
	return false

func _get_animation_info(anim_name: String) -> Dictionary:
	for anim in animations:
		if anim.name == anim_name:
			return {
				"name": anim.name,
				"priority": anim.priority,
				"loop": anim.loop
			}
	return {}

func _get_current_priority() -> int:
	return _get_animation_info(current_animation).get("priority", -1)

func _on_animation_finished(anim_name: String):
	is_busy = false
	var anim_info = _get_animation_info(anim_name)
	
	if not anim_info["loop"]:
		if requested_animation != "":
			play(requested_animation)
			requested_animation = ""
		else:
			play(default_animation)
