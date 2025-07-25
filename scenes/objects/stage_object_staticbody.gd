extends CharacterBody3D

class_name StageObjectCharacterBody3D

@export var object_root: StageObject

func _ready() -> void:
	collision_priority = -10
