extends NetworkStageObject

class_name SimpleDoor

@export var open_angle: float = 45.0
@export var stay_open_time: float = 3.0
@export var opening_time: float = 0.25
@export var closing_time: float = 1.5
@export var open_trans: Tween.TransitionType = Tween.TransitionType.TRANS_QUAD
@export var open_ease: Tween.EaseType = Tween.EaseType.EASE_OUT
@export var close_trans: Tween.TransitionType = Tween.TransitionType.TRANS_CUBIC
@export var close_ease: Tween.EaseType = Tween.EaseType.EASE_IN_OUT
@export var connected_doors: Array[SimpleDoor] = []

enum opcodes {
	OPEN
}

enum door_state {
	CLOSED,
	OPENING,
	OPEN,
	CLOSING
}

var state := door_state.CLOSED

var rot_start: float

var closing_tween: Tween

func _ready() -> void:
	super()
	rot_start = rotation.y

func can_open_door() -> bool:
	if state == door_state.OPENING:
		return false
	if state == door_state.OPEN:
		return false
	return true

func trigger() -> void:
	if !can_open_door():
		return
	
	open()
	send_state(opcodes.OPEN, [])

func open() -> void:
	state = door_state.OPENING
	no_bounce = true
	
	if closing_tween:
		closing_tween.kill()
	
	var tween = create_tween()
	tween.tween_property(self, "rotation:y", rot_start + deg_to_rad(open_angle), opening_time).set_ease(open_ease).set_trans(open_trans)
	tween.finished.connect(func() -> void:
		state = door_state.OPEN
		no_bounce = false
		get_tree().create_timer(stay_open_time, true, true, false).timeout.connect(close)
	)
	
	for door: SimpleDoor in connected_doors:
		if !door.can_open_door():
			continue
		
		door.open()

func close() -> void:
	state = door_state.CLOSING
	no_bounce = true
	closing_tween = create_tween()
	closing_tween.tween_property(self, "rotation:y", rot_start, closing_time).set_ease(close_ease).set_trans(close_trans)
	closing_tween.finished.connect(func() -> void:
		state = door_state.CLOSED
		no_bounce = false
	)

func receive_state(opcode: int, data: Array[Variant]) -> void:
	match opcode:
		opcodes.OPEN:
			open()
	return
