@tool
extends EditorScenePostImport

var collision_body: StaticBody3D
var triggers: Node3D
var global_scene: Node

func _post_import(scene: Node) -> Node:
	global_scene = scene

	iterate(scene)

	var visual_node: Node3D = Node3D.new()
	visual_node.name = "Visual"

	for child: Node in scene.get_children():
		child.reparent(visual_node)
		child.set_meta("_edit_lock_", true)

	scene.add_child(visual_node)
	visual_node.set_owner(scene)
	visual_node.set_meta("_edit_lock_", true)

	triggers = Node3D.new()
	triggers.name = "Triggers"
	scene.add_child(triggers)
	scene.move_child(triggers, 0)
	triggers.set_owner(scene)

	collision_body = StaticBody3D.new()
	collision_body.name = "Colliders"

	scene.add_child(collision_body)
	scene.move_child(collision_body, 0)
	collision_body.set_owner(scene)
	
	for child: Node in visual_node.get_children():
		if not child is MeshInstance3D:
			continue
		generate_collision_shapes(child as MeshInstance3D)
		if child.name.to_lower().ends_with("-nodraw") or child.name.to_lower().ends_with("-fall") or child.name.to_lower() == "fall":
			visual_node.remove_child(child)

	return scene

func iterate(node: Node) -> void:
	for child: Node in node.get_children():
		if child is MeshInstance3D:
			var mesh_instance: MeshInstance3D = child as MeshInstance3D
			mesh_instance.set_layer_mask_value(2, true)  # Enable drop shadows

func generate_collision_shapes(mesh_instance: MeshInstance3D) -> void:
	mesh_instance.name = mesh_instance.mesh.get("surface_0/name")
	
	if mesh_instance.name.to_lower().ends_with("-nocol"):
		return
	
	var fall := false
	if mesh_instance.name.to_lower().ends_with("-fall") or mesh_instance.name.to_lower() == "fall":
		fall = true
		#mesh_instance.create_convex_collision()
		mesh_instance.create_trimesh_collision()
	else:
		mesh_instance.create_trimesh_collision()

	for child: Node in mesh_instance.get_children():
		if not child is StaticBody3D:
			continue
		var static_body: StaticBody3D = child as StaticBody3D
		mesh_instance.remove_child(static_body)
		for shape: Node in static_body.get_children():
			if not shape is CollisionShape3D:
				continue
			for owner_id in static_body.get_shape_owners():
				var owner_transform := static_body.shape_owner_get_transform(owner_id)
				
				for shape_id in range(static_body.shape_owner_get_shape_count(owner_id)):
					var shape_object := static_body.shape_owner_get_shape(owner_id, shape_id)
					static_body.shape_owner_remove_shape(owner_id, shape_id)
					var new_shape_owner := CollisionShape3D.new()
					new_shape_owner.name = mesh_instance.name
					new_shape_owner.shape = shape_object
					
					var new_parent: CollisionObject3D = collision_body
					
					if fall:
						new_parent = FallBoundary.new()
						triggers.add_child(new_parent)
						new_parent.set_owner(global_scene)
					
					new_parent.add_child(new_shape_owner)
					print("Added shape ", new_shape_owner, " to ", new_parent)
					new_shape_owner.set_owner(global_scene)
					new_shape_owner.position = mesh_instance.position
					var new_owner_id := new_parent.create_shape_owner(new_shape_owner)
					new_parent.shape_owner_set_transform(new_owner_id, owner_transform)
				
				static_body.remove_shape_owner(owner_id)
				static_body.process_mode = Node.PROCESS_MODE_DISABLED
