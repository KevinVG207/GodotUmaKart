extends Camera3D

class_name MenuCam

@export var distance: float = 10
var menu_container: Control:
	get:
		return viewport.get_children()[0]
var scale_multi: float = 1.0

@onready var plane: MeshInstance3D = $Plane
@onready var viewport: SubViewport = $SubViewport
@onready var click_area: Area3D = $Plane/Area3D


var opacity: float:
	set(value):
		plane.transparency = 1.0 - value
	get:
		return 1.0 - plane.transparency

func _ready():
	opacity = 0.0
	click_area.input_event.connect(_on_area_3d_input_event)

func _process(_delta):
	var view_rect: Rect2 = get_viewport().get_visible_rect()
	var aspect: float = float(get_viewport().size.x) / get_viewport().size.y
	
	var height: float = 2.0 * distance * tan(deg_to_rad(fov) / 2.0)
	var width: float = height * aspect
	
	plane.scale = Vector3(width, height, 1.0)
	
	var true_scale_multi: float = get_viewport().size.x / view_rect.size.x
	scale_multi = true_scale_multi
	
	viewport.size = get_viewport().size
	viewport.size_2d_override = Vector2(view_rect.size.y * aspect, view_rect.size.y)
	
	menu_container.scale = Vector2(true_scale_multi, true_scale_multi)
	
	plane.mesh.material.albedo_texture = viewport.get_texture()

	plane.global_position = global_position + transform.basis.z * -distance
	
	#plane.transform = transform
	#plane.translate(Vector3(0, 0, distance))


func _on_area_3d_input_event(_camera, event: InputEvent, _position, _normal, _shape_idx):
	viewport.handle_input_locally = true
	event.position *= scale_multi
	event.global_position = event.position
	viewport.push_input(event, true)

func focus():
	if "focus" in viewport.get_child(0):
		viewport.get_child(0).focus()

func has_focus():
	if "given_focus" in viewport.get_child(0):
		viewport.get_child(0).given_focus = true
