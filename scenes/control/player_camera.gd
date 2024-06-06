extends Camera3D

@export var default_fov: float = 75
@export var target: Vehicle3 = null
var offset: Vector3 = Vector3(-5, 2.5, 0)
var offset_bw: Vector3 = Vector3(5, 2.5, 0)
#var offset: Vector3 = Vector3(0, 2, 5)
var look_offset: Vector3 = Vector3(0, 1.2, 0)
var lerp_speed: float = 12
var lerp_speed_look: float = 30
var look_target: Array = []
#var look_target = Vector3.INF
@onready var cur_pos: Vector3 = position
@onready var cur_pos_bw: Vector3 = position
var cur_target: Vector3 = Vector3.INF

var prev_mirror: bool = false

var forwards = true

var in_water = false
var water_areas = {}

func _physics_process(delta):
	if !target:
		return

	var prev_pos = cur_pos
	var prev_pos_bw = cur_pos_bw
	cur_pos = cur_pos.lerp(target.global_transform.translated_local(offset).origin, lerp_speed * delta)
	cur_pos.y = lerpf(prev_pos.y, target.global_transform.translated_local(offset).origin.y, lerp_speed * delta * 0.5)
	cur_pos_bw = cur_pos_bw.lerp(target.global_transform.translated_local(offset_bw).origin, lerp_speed * delta)
	cur_pos_bw.y = lerpf(prev_pos_bw.y, target.global_transform.translated_local(offset_bw).origin.y, lerp_speed * delta * 0.5)

	var mirror = false
	if target.input_mirror:
		transform.origin = cur_pos_bw
		mirror = true
	else:
		transform.origin = cur_pos
	
	var true_target: Vector3 = target.global_transform.origin + look_offset + target.global_transform.basis.z * -target.cur_turn_speed * 0.1

	if mirror != prev_mirror:
		look_at(true_target, -target.gravity.normalized())
	else:
		var old_basis = transform.basis
		look_at(true_target, -target.gravity.normalized())
		var new_basis = transform.basis
		transform.basis = Basis(Quaternion(old_basis).slerp(Quaternion(new_basis), lerp_speed_look * delta))


	prev_mirror = mirror


func _on_camera_area_area_entered(area):
	in_water = true
	water_areas[area] = true
	UI.apply_water()


func _on_camera_area_area_exited(area):
	water_areas.erase(area)
	if water_areas.size() == 0:
		in_water = false
		UI.clear_effect()

func _process(_delta):
	if !target:
		return
		
	fov = default_fov + target.extra_fov
