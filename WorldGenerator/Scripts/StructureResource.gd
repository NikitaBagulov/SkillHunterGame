extends Resource
class_name StructureResource

@export var scenes: Array[PackedScene]  # Сцена структуры (например, лагерь)
@export var biome: String       # Название биома
@export var probability: float  # Вероятность появления в чанке (0.0 - 1.0)
@export var size: Vector2i      # Размер структуры в тайлах (например, 2x2)
