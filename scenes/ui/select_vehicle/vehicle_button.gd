extends MarginContainer

class_name VehicleButton

func set_image(vehicle_name: String):
	$Panel/VehicleImage.texture = Util.get_vehicle_texture(vehicle_name)
