extends Resource
class_name ObjectResource

@export var scenes: Array[PackedScene]  # Сцены объекта (дерево, враг и т.д.)
@export var biome: String              # Название биома ("Grass", "Forest" и т.д.)
@export var probability: float         # Вероятность появления (0.0 - 1.0)
@export var density_noise_scale: float = 0.1  # Масштаб шума для кластеризации
@export var min_distance: float = 16.0  # Минимальное расстояние между объектами (в пикселях)
@export var offset_range: float = 8.0   # Максимальное смещение от центра тайла (в пикселях)
@export var max_objects_per_area: int = 5  # Максимальное количество объектов на 100x100 пикселей
@export var is_enemy: bool = false      # Флаг: является ли объект врагом
