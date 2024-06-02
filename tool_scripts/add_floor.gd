@tool
extends EditorScript


# Called when the script is executed (using File -> Run in Script Editor).
func _run():
	for child in get_scene().get_children():
		if child is MeshInstance3D:
			for child2 in child.get_children():
				if child2 is StaticBody3D:
					print(child2.get_groups())
					if not child2.is_in_group("floor"):
						child2.add_to_group("floor")
