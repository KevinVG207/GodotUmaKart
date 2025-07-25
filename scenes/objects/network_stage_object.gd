extends StageObject

class_name NetworkStageObject

func _ready() -> void:
	world.register_object(self)

func send_state(opcode: int, data: Array[Variant]) -> void:
	world.send_object_state(self, opcode, data)

func receive_state(opcode: int, data: Array[Variant]) -> void:
	# Override
	return
