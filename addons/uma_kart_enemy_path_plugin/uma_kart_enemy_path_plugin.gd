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

	for next_point in point.next_points:
		if next_point == null:
			continue
		
		draw_sampled_curve(RaceUtil.make_curve_between_pathpoints(point, next_point), overlay)

func draw_sampled_curve(curve: Curve3D, overlay: Control) -> void:
	#print("draw sampled curve: ", curve)
	var points := curve.get_baked_points()
	var cam = EditorInterface.get_editor_viewport_3d().get_camera_3d()
	
	for i in range(points.size()-1):
		var p1 := points[i]
		var p2 := points[i+1]
		
		if cam.is_position_behind(p1) or cam.is_position_behind(p2):
			continue
		if !cam.is_position_in_frustum(p1) and !cam.is_position_in_frustum(p2):
			continue
		
		var p1_2d = cam.unproject_position(p1)
		var p2_2d = cam.unproject_position(p2)
		
		overlay.draw_line(p1_2d, p2_2d, LINE_COLOR, 1, true)
	return

func recursive_find_points(node: Node, list: Array) -> void:
	for child in node.get_children():
		recursive_find_points(child, list)
	if node is EnemyPath:
		list.append(node)
