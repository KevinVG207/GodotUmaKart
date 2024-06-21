extends AnimationTree

class_name VehicleAnimationTree

const Type = {
	idle = "RESET",
	dmg_spin = "dmg_spin",
}

var sm: AnimationNodeStateMachinePlayback = self.get("parameters/playback")
var animation:
	set(value):
		sm.travel(value)
	get:
		return sm.get_current_node()

#func _ready():
	#animation = Type.idle

func _process(delta):
	#animation = Type.dmg_spin
	#print(sm.get_current_node())
	pass
