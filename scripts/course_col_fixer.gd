extends Node3D

func _enter_tree() -> void:
	var sb := StaticBody3D.new()
	add_child(sb)
	for child: Object in get_children():
		if child is not MeshInstance3D:
			continue
		var mesh := child as MeshInstance3D
		for child2: Object in mesh.get_children():
			if child2 is not StaticBody3D:
				continue
			var static_body := child2 as StaticBody3D
			
			for owner_id in static_body.get_shape_owners():
				var owner_object := static_body.shape_owner_get_owner(owner_id) as Node3D
				var owner_transform := static_body.shape_owner_get_transform(owner_id)
				
				for shape_id in range(static_body.shape_owner_get_shape_count(owner_id)):
					var shape_object := static_body.shape_owner_get_shape(owner_id, shape_id)
					static_body.shape_owner_remove_shape(owner_id, shape_id)
					var new_shape_owner := CollisionShape3D.new()
					new_shape_owner.shape = shape_object
					sb.add_child(new_shape_owner)
					new_shape_owner.position = mesh.position
					var new_owner_id = sb.create_shape_owner(new_shape_owner)
					sb.shape_owner_set_transform(new_owner_id, owner_transform)
					
					for group in owner_object.get_groups():
						print("Adding group ", group)
						new_shape_owner.add_to_group(group)
				
				static_body.remove_shape_owner(owner_id)
				static_body.process_mode = Node.PROCESS_MODE_DISABLED
			mesh.remove_child(static_body)
