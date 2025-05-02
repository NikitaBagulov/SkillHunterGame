# Portal.gd
class_name Portal
extends Area2D

@export var target_scene: PackedScene # Сцена, в которую переходит игрок
@export var spawn_position: Vector2 = Vector2.ZERO # Позиция спавна в целевой сцене
@export var is_hub_to_world: bool = false # Флаг: переход из хаба в мир или обратно
@export var portal_id: String = "" # Уникальный ID для парного связывания порталов


var current_scene = null

func _ready():
	body_entered.connect(_on_body_entered)
	if not target_scene:
		push_warning("Portal: Target scene not set for portal ", name)
	if portal_id == "":
		push_warning("Portal: Portal ID not set for portal ", name)

func _on_body_entered(body: Node):
	if body is Player:
		if not target_scene:
			push_error("Portal: Cannot transition, target scene not set!")
			return
		PlayerManager.PLAYER_STATS.position = body.global_position

		if is_hub_to_world:
			var world_node = get_tree().root.get_node("MainRoot").get_node("World")
			if world_node == null:
				var world_instance = target_scene.instantiate()
				get_tree().root.get_node("MainRoot").add_child(world_instance)
				get_tree().root.get_node("MainRoot").get_node("StartLocation").visible = false
				get_tree().root.get_node("MainRoot").get_node("StartLocation").process_mode = Node.PROCESS_MODE_DISABLED
				get_tree().root.get_node("MainRoot").get_node("StartLocation").get_node("GroundedLayer").collision_enabled = false
				get_tree().root.get_node("MainRoot").get_node("StartLocation").get_node("ObjectLayer").collision_enabled = false
		else:
			get_tree().root.get_node("MainRoot").get_node("World").queue_free()
			get_tree().root.get_node("MainRoot").get_node("StartLocation").visible = true
			get_tree().root.get_node("MainRoot").get_node("StartLocation").process_mode = Node.PROCESS_MODE_INHERIT
			get_tree().root.get_node("MainRoot").get_node("StartLocation").get_node("GroundedLayer").collision_enabled = true
			get_tree().root.get_node("MainRoot").get_node("StartLocation").get_node("ObjectLayer").collision_enabled = true
		
		PlayerManager.set_player_position(spawn_position + Vector2(0, 50))
		PlayerManager.player_spawned = false
		print("position: ", self.global_position, PlayerManager.player.global_position)
