class_name LevelTileMap extends TileMapLayer

var world_generator: WorldGenerator

# Called when the node enters the scene tree for the first time.
func _ready():
	if get_parent() is WorldGenerator:
		world_generator = get_parent() as WorldGenerator
	else:
		push_error("LevelTileMap должен быть дочерним элементом WorldGenerator!")
		return
	
	# Инициализация границ через WorldGenerator
	update_bounds()

func update_bounds():
	if world_generator:
		var bounds = world_generator.get_current_bounds()
		LevelManager.change_tilemap_bounds(bounds)

# Метод для получения текущих границ (если нужно вызывать вручную)
func get_tilemap_bounds() -> Array[Vector2]:
	if world_generator:
		return world_generator.get_current_bounds()
	return [Vector2.ZERO, Vector2.ZERO]  # Значение по умолчанию, если границы не определены
