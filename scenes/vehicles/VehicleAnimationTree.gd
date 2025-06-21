extends AnimationTree

class_name VehicleAnimationTree

@onready var vehicle: Vehicle4 = get_parent()

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

const CHARGEUP_BLEND := "parameters/Rest/Chargeup/blend_amount"
const CHARGEUP_SPEED := "parameters/Rest/ChargeupSpeed/scale"
const SQUISH_BLEND := "parameters/Rest/Squish/blend_amount"
var squish_amount: float = 0.0
const SCALE_BLEND := "parameters/Rest/Scale/blend_amount"
var scale: float = 1.0

#func _ready():
	#animation = Type.idle

func _process(delta):
	blend_chargeup()
	self.set(SQUISH_BLEND, squish_amount)
	self.set(SCALE_BLEND, scale - 1.0)

func blend_chargeup():
	if vehicle.started:
		self.set(CHARGEUP_BLEND, 0)
		self.set(CHARGEUP_SPEED, 0)
		return
	var ratio := clampf(vehicle.countdown_gauge / vehicle.countdown_gauge_max, 0 , 1)
	var blend := remap(ratio, 0, 1, 0, 0.25)
	self.set(CHARGEUP_BLEND, blend)
	var speed := clampf(remap(ratio, 0, 1, 0, 10), 0, 2.0)
	self.set(CHARGEUP_SPEED, speed)
	
