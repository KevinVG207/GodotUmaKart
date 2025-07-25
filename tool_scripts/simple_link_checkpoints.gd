@tool
extends EditorScript

var scene: Node3D = get_scene()

func _run() -> void:
	var points := scene.get_node("%Checkpoints").get_children()
	for i in range(points.size()-1):
		var next := points[i]
		if not next is Checkpoint:
			continue
		var cur_point := points[i] as Checkpoint
		var next_point := points[i+1] as Checkpoint
		
		var new_array := cur_point.next_points.duplicate()
		
		if next_point in new_array:
			continue
		
		new_array.append(next_point)
		
		cur_point.next_points = new_array
