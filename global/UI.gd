extends Control

var water = false
@export var underwater_color: Color
var transparent: Color = Color(0, 0, 0, 0)

var race_ui_scene: PackedScene = preload("res://scenes/ui/race_ui.tscn")
@onready var race_ui: RaceUI = $RaceUI
var _next_scene: String
var is_loading: bool = false
var wait_after_transition: bool = false
var middle_reached: bool = false
@onready var transition_layer: CanvasLayer = $Transition
var transition_instance: SceneTransition = null
var default_transition: PackedScene = preload("res://scenes/ui/transition/default_transition.tscn")

func _process(_delta):
	if _next_scene and transition_instance.can_swap:
		if !is_loading:
			start_loading_scene()
		else:
			var progress: Array = []
			var status: int = ResourceLoader.load_threaded_get_status(_next_scene, progress)
			transition_instance.progress = progress[0]
			if status == ResourceLoader.THREAD_LOAD_LOADED and middle_reached:
				swap_scenes()
				if !wait_after_transition:
					end_scene_change()

func show_race_ui():
	race_ui.visible = true

func hide_race_ui():
	race_ui.pause_menu.disable()
	race_ui.visible = false
	
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
	for vehicle: Vehicle4 in vehicles:
		rank_strings.append("#" + str(vehicle.rank) + ": " + vehicle.username)
	race_ui.get_node("Ranks").text = "\n".join(rank_strings)

func change_scene(next_scene_path: String, wait: bool = false, transition: PackedScene=default_transition):
	if _next_scene or transition_instance:
		return
	is_loading = false
	_next_scene = next_scene_path
	wait_after_transition = wait
	middle_reached = false
	
	transition_instance = transition.instantiate() as SceneTransition
	transition_layer.add_child(transition_instance)
	transition_instance.middle_reached.connect(_on_scene_transition_middle)
	transition_instance.start()
	#var tween = create_tween()
	#tween.tween_property($Transition/ColorRect, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	#tween.finished.connect(_on_scene_transition_middle)

func start_loading_scene():
	if is_loading or not _next_scene:
		return
	is_loading = true
	ResourceLoader.load_threaded_request(_next_scene, "", true)

func _on_scene_transition_middle():
	start_loading_scene()
	transition_instance.can_swap = true
	middle_reached = true
	#if not wait_after_transition:
		#swap_scenes()
		#end_scene_change()

func swap_scenes():
	if not _next_scene:
		Debug.print("Err: Swapping scenes without a scene path set!")
	
	# Fetch the scene and change.
	get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(_next_scene))
	hide_race_ui()
	transition_instance.progress = 1.0
	is_loading = false
	_next_scene = ""

func end_scene_change():
	if transition_instance:
		transition_instance.end()
		transition_instance = null
