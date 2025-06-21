extends RigidBody3D

signal integrate_forces(state: PhysicsDirectBodyState3D)
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	integrate_forces.emit(state)
