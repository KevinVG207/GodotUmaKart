extends Node3D


func _ready():
	$PlayerCamera.target = $Vehicle
	
	print("TEST")
	var v1 = Vector2(1,1).normalized()
	var v2 = Vector2(0,1)
	print(v1.dot(v2)/v2.length())
