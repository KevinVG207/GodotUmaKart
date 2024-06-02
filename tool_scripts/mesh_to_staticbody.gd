@tool
extends EditorScript


# Called when the script is executed (using File -> Run in Script Editor).
func _run():
	for child in get_scene().get_children():
		if child is MeshInstance3D:
			child.create_trimesh_collision()
