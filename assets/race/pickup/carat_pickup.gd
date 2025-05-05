extends Node3D

var mesh: MeshInstance3D
var body_mat: ShaderMaterial
var rot_offset := randf()*2*PI

func _ready() -> void:
	mesh = get_child(0).get_child(0) as MeshInstance3D
	mesh.set_instance_shader_parameter("leaves_random_offset", Vector2(randf(), randf()))
	body_mat = mesh.get_surface_override_material(0) as ShaderMaterial
	

func _process(_delta: float) -> void:
	var viewport_coords := get_viewport().get_camera_3d().unproject_position(global_position)
	var coords = viewport_coords / Vector2(get_viewport().size) * get_window().content_scale_factor
	mesh.set_instance_shader_parameter("offset_in_viewport", coords)
	mesh.set_instance_shader_parameter("rot_offset", rot_offset)
	#body_mat.set_shader_parameter("ui_scale", get_window().content_scale_factor)
