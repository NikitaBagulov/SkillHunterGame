class_name BiomeSettings extends Node

@export var biomes = [
	[0, "Water", -1.0, -0.5, 1.0],
	[1, "Grass", -0.5, 0.0, 1.0],
	[0, "Water", 0.0, 0.2, 1.0],
	[3, "Forest", 0.2, 0.6, 1.0],
	[0, "Water", 0.6, 0.7, 1.0],
	[2, "Winter", 0.7, 1.0, 1.0]
]

@export var object_resources: Array[ObjectResource]
@export var structure_resources: Array[StructureResource]
@export var boss_scenes: Array[PackedScene]

var terrain_to_biome = {}

func _ready():
	for biome in biomes:
		if not terrain_to_biome.has(biome[0]):
			terrain_to_biome[biome[0]] = biome[1]
