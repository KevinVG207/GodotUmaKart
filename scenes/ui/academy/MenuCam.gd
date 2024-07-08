extends Camera3D

class_name MenuCam

@export var plane: MeshInstance3D
@export var viewport: SubViewport
@export var distance: float = 50
var menu_container: Control

var opacity: float:
	set(value):
		plane.transparency = 1.0 - value
	get:
		return 1.0 - plane.transparency

func _enter_tree():
	opacity = 0.0
	menu_container = viewport.get_children()[0]

func _process(_delta):
	var view_rect: Rect2 = get_viewport().get_visible_rect()
	var aspect: float = float(get_viewport().size.x) / get_viewport().size.y
	
	var height: float = 2.0 * distance * tan(deg_to_rad(fov) / 2.0)
	var width: float = height * aspect
	
	plane.scale = Vector3(width, height, 1.0)
	
	var true_scale_multi: float = get_viewport().size.x / view_rect.size.x
	
	viewport.size = get_viewport().size
	viewport.size_2d_override = Vector2(view_rect.size.y * aspect, view_rect.size.y)
	
	menu_container.scale = Vector2(true_scale_multi, true_scale_multi)
	
	plane.mesh.material.albedo_texture = viewport.get_texture()

	plane.global_position = global_position + transform.basis.z * -distance
	
	#plane.transform = transform
	#plane.translate(Vector3(0, 0, distance))


func _on_area_3d_input_event(camera: Camera3D, event, _position, _normal, _shape_idx):
	#print(event.position)
	viewport.handle_input_locally = true
	Input.parse_input_event(event)
	#print(get_viewport().is_input_handled())
	#viewport.set_process_input(true)
	#viewport.push_unhandled_input(event)
	#print(get_viewport().is_input_handled())
	viewport.handle_input_locally = false
