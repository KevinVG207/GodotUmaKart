extends CollisionShape3D

class_name CourseCollisionShape3D

@export var mesh: MeshInstance3D = null

func _ready() -> void:
	add_inv_wall_to_wall_group()
	hide_shadows()

func add_inv_wall_to_wall_group() -> void:
	var parent := get_parent_node_3d()
	if not parent:
		return
	
	if parent.name.begins_with("InvWall"):
		add_to_group("col_wall")

func hide_shadows() -> void:
	if !mesh:
		return
	
	if !is_in_group("col_wall"):
		return
	
	mesh.set_layer_mask_value(2, false)
