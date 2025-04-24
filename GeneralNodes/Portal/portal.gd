# Portal.gd
class_name Portal
extends Area2D

@export var target_scene: PackedScene # Сцена, в которую переходит игрок
@export var spawn_position: Vector2 = Vector2.ZERO # Позиция спавна в целевой сцене
@export var is_hub_to_world: bool = false # Флаг: переход из хаба в мир или обратно
@export var portal_id: String = "" # Уникальный ID для парного связывания порталов


var current_scene = null

func _ready():
	# Подключаем сигнал входа игрока
	body_entered.connect(_on_body_entered)
	if not target_scene:
		push_warning("Portal: Target scene not set for portal ", name)
	if portal_id == "":
		push_warning("Portal: Portal ID not set for portal ", name)
	#print("Portal: Initialized at ", global_position, " with ID: ", portal_id)

func _on_body_entered(body: Node):
	if body is Player:
		#print("Portal: Player entered portal ", name, " with ID: ", portal_id)
		if not target_scene:
			push_error("Portal: Cannot transition, target scene not set!")
			return
		# Сохраняем текущую позицию игрока в PLAYER_STATS
		PlayerManager.PLAYER_STATS.position = body.global_position
		#print("Portal: Saving player position: ", PlayerManager.PLAYER_STATS.position)
		
		# Переходим в целевую сцену
		if is_hub_to_world:
			var world_node = get_tree().root.get_node("MainRoot").get_node("World")
			if world_node == null:
				#print("Portal: Transitioning from hub to world")
				var world_instance = target_scene.instantiate()
				get_tree().root.get_node("MainRoot").add_child(world_instance)
				get_tree().root.get_node("MainRoot").get_node("StartLocation").visible = false
				get_tree().root.get_node("MainRoot").get_node("StartLocation").process_mode = Node.PROCESS_MODE_DISABLED
				get_tree().root.get_node("MainRoot").get_node("StartLocation").get_node("GroundedLayer").collision_enabled = false
				get_tree().root.get_node("MainRoot").get_node("StartLocation").get_node("ObjectLayer").collision_enabled = false
			else:
				get_tree().root.get_node("MainRoot").get_node("StartLocation").visible = false
				get_tree().root.get_node("MainRoot").get_node("StartLocation").process_mode = Node.PROCESS_MODE_DISABLED
				get_tree().root.get_node("MainRoot").get_node("StartLocation").get_node("GroundedLayer").collision_enabled = false
				get_tree().root.get_node("MainRoot").get_node("StartLocation").get_node("ObjectLayer").collision_enabled = false
				
				get_tree().root.get_node("MainRoot").get_node("World").visible = true
				get_tree().root.get_node("MainRoot").get_node("World").process_mode = Node.PROCESS_MODE_INHERIT
				get_tree().root.get_node("MainRoot").get_node("World").get_node("GroundedLayer").collision_enabled = true
		else:
			get_tree().root.get_node("MainRoot").get_node("World").visible = false
			get_tree().root.get_node("MainRoot").get_node("World").process_mode = Node.PROCESS_MODE_DISABLED
			get_tree().root.get_node("MainRoot").get_node("World").get_node("GroundedLayer").collision_enabled = true
			
			get_tree().root.get_node("MainRoot").get_node("StartLocation").visible = true
			get_tree().root.get_node("MainRoot").get_node("StartLocation").process_mode = Node.PROCESS_MODE_INHERIT
			get_tree().root.get_node("MainRoot").get_node("StartLocation").get_node("GroundedLayer").collision_enabled = true
			get_tree().root.get_node("MainRoot").get_node("StartLocation").get_node("ObjectLayer").collision_enabled = true
		
		# Устанавливаем позицию игрока после перехода
		PlayerManager.set_player_position(spawn_position)
		PlayerManager.player_spawned = false
		#print("Portal: Setting player spawn position to ", spawn_position)
