extends DetachedItem

class_name JuiceSpill

@onready var body: Node3D = %Node3D
var is_ready: bool = false

func _ready() -> void:
	grace_time = 0.0
	super()
	%Node3D.visible = false
	%Area3D.body_entered.connect(_on_area_3d_body_entered)

func _physics_process(delta: float) -> void:
	super(delta)
	if !is_ready:
		return
	
	%Node3D.visible = true
	%Area3D.monitoring = true

func get_state() -> Dictionary:
	return {
		"p": Util.to_array(body.global_position),
		"r": Util.to_array(body.global_rotation),
		"i": is_ready
	}
	
func set_state(state: Dictionary) -> void:
	body.global_position = Util.to_vector3(state.p)
	body.global_rotation = Util.to_vector3(state.r)
	is_ready = state.i

func _on_area_3d_body_entered(body: Variant) -> void:
	if body == self:
		return
	
	if not body is Vehicle4:
		return
	
	var vehicle := body as Vehicle4
	
	if vehicle.is_network:
		return
	
	if vehicle == origin and grace_ticks > 0:
		return
	
	vehicle.damage(Vehicle4.DamageType.SPIN)
	destroy()
