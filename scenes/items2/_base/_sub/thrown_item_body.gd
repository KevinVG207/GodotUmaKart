extends RigidBody3D

var parent: ThrownItem

func _ready() -> void:
	parent = get_parent()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	parent._integrate_forces(state)
