extends Camera3D

class_name MenuCam

@export var plane: MeshInstance3D
@export var viewport: SubViewport
@export var distance: float = 50

var opacity: float:
	set(value):
		plane.transparency = 1.0 - value
	get:
		return 1.0 - plane.transparency

func _enter_tree():
	opacity = 0.0

func _process(_delta):
	var view_rect: Rect2 = get_viewport().get_visible_rect()
	var aspect: float = float(get_viewport().size.x) / get_viewport().size.y
	
	var height: float = 2.0 * distance * tan(deg_to_rad(fov) / 2.0)
	var width: float = height * aspect
	
	plane.scale = Vector3(width, height, 1.0)
	
	var true_scale_multi: float = get_viewport().size.x / view_rect.size.x
	
	viewport.size = get_viewport().size
	viewport.size_2d_override = Vector2(view_rect.size.y * aspect, view_rect.size.y)
	
	for child: Control in viewport.get_children():
		child.scale = Vector2(true_scale_multi, true_scale_multi)
	
	plane.mesh.material.albedo_texture = viewport.get_texture()

	plane.global_position = global_position + transform.basis.z * -distance
	
	#plane.transform = transform
	#plane.translate(Vector3(0, 0, distance))
