extends Camera3D

@export var plane: MeshInstance3D
@export var viewport: SubViewport
@export var distance: float = 50

func _process(_delta):
	var view_rect: Rect2 = get_viewport().get_visible_rect()
	var aspect: float = view_rect.size.x / view_rect.size.y
	
	var height: float = 2.0 * distance * tan(deg_to_rad(fov) / 2.0)
	var width: float = height * aspect
	
	plane.scale = Vector3(width, height, 1.0)
	
	var true_scale_multi: float = get_viewport().size.x / view_rect.size.x
	
	viewport.size = view_rect.size * 1.0
	
	plane.mesh.material.albedo_texture = viewport.get_texture()

	plane.global_position = global_position + transform.basis.z * -distance
	
	#plane.transform = transform
	#plane.translate(Vector3(0, 0, distance))
