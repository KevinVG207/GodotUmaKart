extends Node3D

@export var hide_tail: bool = false:
	set(value):
		$Armature/Skeleton3D/Tail.visible = !value

func _ready() -> void:
	hide_tail = hide_tail
