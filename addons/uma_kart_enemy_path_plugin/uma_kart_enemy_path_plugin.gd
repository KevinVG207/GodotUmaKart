@tool
extends EditorPlugin

var base
const LINE_COLOR := Color.RED

func _handles(object: Object) -> bool:
	if not object is RaceBase and not object is EnemyPath:
		return false
	
	base = object
	return true

func _forward_3d_gui_input(camera, event):
	update_overlays()
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func _forward_3d_draw_over_viewport(overlay: Control) -> void:
	var points := []
	if base is RaceBase:
		recursive_find_points(base, points)
	else:
		var container = base.find_parent("EnemyPathPoints")
		if container == null:
			print("Not found")
			return
		recursive_find_points(container.get_parent(), points)
		
	for point in points:
		draw_point_lines(point, overlay)
	
func draw_point_lines(point: EnemyPath, overlay: Control) -> void:
	if point == null:
		return
	
	var cam = EditorInterface.get_editor_viewport_3d().get_camera_3d()
	var start_coords = cam.unproject_position(point.global_position)
	if cam.is_position_behind(point.global_position):
		return
	
	for next_point in point.next_points:
		if next_point == null:
			continue
		
		if !cam.is_position_in_frustum(point.global_position) and !cam.is_position_in_frustum(next_point.global_position):
			continue
		
		var end_coords = cam.unproject_position(next_point.global_position)
		if cam.is_position_behind(next_point.global_position):
			continue
		
		overlay.draw_line(start_coords, end_coords, LINE_COLOR, 1, true)

func recursive_find_points(node: Node, list: Array) -> void:
	for child in node.get_children():
		recursive_find_points(child, list)
	if node is EnemyPath:
		list.append(node)
