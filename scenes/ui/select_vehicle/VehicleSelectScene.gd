extends Control

@export var vehicle_button_scene: PackedScene
@onready var grid: GridContainer = $ListContainer/ScrollContainer/GridContainer

func _ready():
	for vehicle_name in Util.get_vehicles():
		var new_btn: VehicleButton = vehicle_button_scene.instantiate()
		new_btn.set_image(vehicle_name)
		grid.add_child(new_btn)
