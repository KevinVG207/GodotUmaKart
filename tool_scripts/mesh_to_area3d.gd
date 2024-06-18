@tool
extends EditorScript


# Called when the script is executed (using File -> Run in Script Editor).
func _run():
	for child in get_scene().get_children():
		if child is MeshInstance3D and child.name.substr(0, 4) == "fall":
			child.visible = false
			var has_area = false
			for child2 in child.get_children():
				if child2 is Area3D:
					has_area = true
					child2.set_script(load("res://scenes/levels/FallBoundary.gd"))
					child2 = child2 as Area3D
					child2.collision_layer = 0
					child2.collision_mask = 0
					child2.set_collision_layer_value(9, true)
					child2.set_collision_mask_value(2, true)
					child2.set_collision_mask_value(3, true)
					print("a")
					break
			if has_area:
				continue
			child.create_convex_collision()
