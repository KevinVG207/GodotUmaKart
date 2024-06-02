extends RigidBody3D

@export var max_speed: float
@onready var max_reverse_speed: float = max_speed * 0.5
@export var initial_accel: float
@export var accel_exponent: float

@onready var friction_initial_accel: float = initial_accel * 1.5
@onready var friction_exponent: float = accel_exponent

@onready var brake_initial_accel: float = initial_accel * 2.0
@onready var brake_exponent: float = accel_exponent

@onready var reverse_initial_accel: float = initial_accel * 0.5
@onready var reverse_exponent: float = accel_exponent

@export var small_boost_max_speed: float
@onready var small_boost_initial_accel: float = initial_accel * 2
@onready var small_boost_exponent = accel_exponent

@export var big_boost_max_speed: float

@export var miniturbo_duration: float

var still_turbo_max_speed: float = 1
var still_turbo_ready: bool = false

var cur_speed: float = 0
var _vel: Vector3 = Vector3.ZERO

func _ready():
	pass

func _physics_process(delta):
	var is_accel = Input.is_action_pressed("accelerate")
	var is_brake = Input.is_action_pressed("brake")
	var steering = Input.get_axis("left", "right")
	
	#print(is_accel, is_brake, steering)
	
	if is_accel and is_brake:
		# TODO: Check for drift
		# Decelerate to standstill
		cur_speed += get_brake_speed(delta)
		
		# Check if we can miniturbo
		if abs(cur_speed) <= still_turbo_max_speed:
			# Do miniturbo.
			if not still_turbo_ready and $StillTurboTimer.is_stopped():
				$StillTurboTimer.start()
				print("Start building up miniturbo")
	else:
		if is_accel:
			if still_turbo_ready:
				still_turbo_ready = false
				# Perform miniturbo.
				print("Performing miniturbo")
				$SmallBoostTimer.start(miniturbo_duration)
				
			cur_speed += get_accel_speed(delta)
		elif is_brake:
			cur_speed += get_reverse_speed(delta)
		else:
			cur_speed += get_friction_speed(delta)
		
		if not $StillTurboTimer.is_stopped():
			$StillTurboTimer.stop()
			print("Stopped building up miniturbo")
		if still_turbo_ready:
			still_turbo_ready = false
			print("Cancelled miniturbo")
	
	# Apply boosts
	cur_speed += get_boost_speed(delta)

	print(cur_speed)
	
	# TODO: Delet this
	linear_velocity = Vector3(cur_speed, 0, 0)


func get_accel_speed(delta: float) -> float:
	if cur_speed < 0:
		# Braking
		return brake_initial_accel * delta

	# Accelerating
	return Util.get_vehicle_accel(max_speed, cur_speed, initial_accel, accel_exponent) * delta


func get_reverse_speed(delta: float) -> float:
	if cur_speed > 0:
		# Braking
		return -brake_initial_accel * delta

	# Reversing
	return -Util.get_vehicle_accel(max_reverse_speed, -cur_speed, reverse_initial_accel, reverse_exponent) * delta


func get_brake_speed(delta: float) -> float:
	var mult = -1.0

	if cur_speed < 0:
		mult = 1.0

	return Util.get_vehicle_accel(max_reverse_speed, abs(abs(cur_speed) - max_reverse_speed), brake_initial_accel, brake_exponent) * delta * mult


func get_friction_speed(delta: float) -> float:
	var mult = -1.0

	if cur_speed < 0:
		mult = 1.0

	return Util.get_vehicle_accel(max_speed, abs(abs(cur_speed) - max_speed), friction_initial_accel, friction_exponent) * delta * mult


func get_boost_speed(delta: float) -> float:
	if not $SmallBoostTimer.is_stopped():
		# Small boost is active
		return Util.get_vehicle_accel(small_boost_max_speed, cur_speed, small_boost_initial_accel, small_boost_exponent) * delta
	
	if cur_speed > max_speed:
		var speed_range = big_boost_max_speed - max_speed
		var ratio = big_boost_max_speed - cur_speed
		return -Util.get_vehicle_accel(speed_range, ratio, friction_initial_accel, friction_exponent) * delta
	return 0

func _on_still_turbo_timer_timeout():
	print("Miniturbo ready")
	still_turbo_ready = true
