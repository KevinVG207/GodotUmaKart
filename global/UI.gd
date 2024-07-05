extends Control

var water = false
@export var underwater_color: Color
var transparent: Color = Color(0, 0, 0, 0)

var race_ui_scene: PackedScene = preload("res://scenes/ui/race_ui.tscn")
@onready var race_ui: RaceUI = $RaceUI
var _next_scene: PackedScene
var wait_after_transition: bool = false
@onready var transition_layer: CanvasLayer = $Transition
var transition_instance: SceneTransition = null
var default_transition: PackedScene = preload("res://scenes/ui/transition/default_transition.tscn")

func show_race_ui():
	race_ui.visible = true
	
func reset_race_ui():
	race_ui.visible = false
	race_ui.queue_free()
	var new_race_ui = race_ui_scene.instantiate()
	add_child(new_race_ui)
	race_ui = new_race_ui

func apply_water():
	if not water:
		water = true
		var tween = create_tween()
		tween.tween_property(race_ui.get_node("ColorRect"), "color", underwater_color, 0.2).set_trans(Tween.TRANS_CUBIC)

func clear_effect():
	water = false
	var tween = create_tween()
	tween.tween_property(race_ui.get_node("ColorRect"), "color", transparent, 0.2).set_trans(Tween.TRANS_CUBIC)

func update_ranks(vehicles: Array):
	var rank_strings = []
	for vehicle: Vehicle3 in vehicles:
		rank_strings.append("#" + str(vehicle.rank) + ": " + vehicle.username)
	race_ui.get_node("Ranks").text = "\n".join(rank_strings)

func change_scene(next_scene: PackedScene, wait: bool = false, transition: PackedScene=default_transition):
	if _next_scene or transition_instance:
		return
	_next_scene = next_scene
	wait_after_transition = wait
	
	transition_instance = transition.instantiate() as SceneTransition
	transition_layer.add_child(transition_instance)
	transition_instance.middle_reached.connect(_on_scene_transition_middle)
	transition_instance.start()
	#var tween = create_tween()
	#tween.tween_property($Transition/ColorRect, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	#tween.finished.connect(_on_scene_transition_middle)

func _on_scene_transition_middle():
	get_tree().change_scene_to_packed(_next_scene)
	if not wait_after_transition:
		end_scene_change()
	
func end_scene_change():
	_next_scene = null
	if transition_instance:
		transition_instance.end()
		transition_instance = null
