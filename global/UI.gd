extends Control

var water = false
@export var underwater_color: Color
var transparent: Color = Color(0, 0, 0, 0)

var race_ui_scene: PackedScene = preload("res://scenes/ui/race_ui.tscn")
@onready var race_ui: RaceUI = $RaceUI
var _next_scene: PackedScene
var wait_after_transition: bool = false

var top_rect_start: float = 301
var top_rect_end: float = -1057
var bottom_rect_start: float = 1667
var bottom_rect_end: float = 270

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

func change_scene(next_scene: PackedScene, wait: bool = false):
	if _next_scene:
		return
	_next_scene = next_scene
	wait_after_transition = wait
	$Transition/BottomRect.position.y = bottom_rect_start
	$Transition/BottomRect.visible = true
	$Transition/TopRect.position.y = top_rect_end
	$Transition/TopRect.visible = false
	
	var tween = create_tween()
	tween.tween_property($Transition/BottomRect, "position:y", bottom_rect_end, 0.5)
	tween.finished.connect(_on_scene_transition_middle)

func _on_scene_transition_middle():
	get_tree().change_scene_to_packed(_next_scene)
	if not wait_after_transition:
		end_scene_change()
	
func end_scene_change():
	if not _next_scene:
		return
	
	_next_scene = null
	$Transition/BottomRect.position.y = bottom_rect_start
	$Transition/BottomRect.visible = false
	$Transition/TopRect.position.y = top_rect_start
	$Transition/TopRect.visible = true
	
	var tween = create_tween()
	tween.tween_property($Transition/TopRect, "position:y", top_rect_end, 0.5)
