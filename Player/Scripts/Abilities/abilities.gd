class_name PlayerAbilities extends Node

const BOOMERANG = preload("res://Player/Weapons/Boomerang.tscn")

enum abilities {BOOMERANG, GRAPPLE}

var selected_ability = abilities.BOOMERANG
var player: Player
var boomerang_instance: Boomerang = null

func _ready():
	#await get_tree().create_timer(1).timeout
	player = PlayerManager.get_player()

func _unhandled_input(event):
	if event.is_action_pressed("ability"):
		if player != null:
			if selected_ability == abilities.BOOMERANG:
				boomerang_ability()
	pass
	
func boomerang_ability() -> void:
	if boomerang_instance != null:
		return
	var _b = BOOMERANG.instantiate() as Boomerang
	player.add_sibling(_b)
	_b.global_position = player.global_position
	
	var throw_direction = player.direction
	if throw_direction == Vector2.ZERO:
		throw_direction = player.cardinal_direction
	
	_b.throw(throw_direction)
	boomerang_instance = _b
	
	pass	
