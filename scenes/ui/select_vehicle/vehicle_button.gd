extends MarginContainer

class_name VehicleButton

var vehicle_name: String

func set_vehicle(new_vehicle_name: String):
	vehicle_name = new_vehicle_name
	_update_image()

func _update_image():
	$Button/VehicleImage.texture = Util.get_vehicle_texture(vehicle_name)
