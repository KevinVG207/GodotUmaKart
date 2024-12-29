extends Control

class_name AudioSetting

var bus_name := ""

func set_bus(new_name: String):
	bus_name = new_name
	%HSlider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name)))

func _on_h_slider_value_changed(volume: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), linear_to_db(volume))
