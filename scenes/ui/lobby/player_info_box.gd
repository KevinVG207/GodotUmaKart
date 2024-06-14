extends HBoxContainer

class_name LobbyPlayerInfoBox

@export var current_user_color: Color
@export var picked_color: Color

#func _enter_tree():
	#resize()
#
#func resize():
	#var c: MarginContainer = get_parent().get_parent()
	#var g: GridContainer = get_parent()
	#custom_minimum_size.x = floor((c.size.x - c.get("theme_override_constants/margin_right") - c.get("theme_override_constants/margin_left") - get("theme_override_constants/separation") - g.get("theme_override_constants/h_separation")) / 2)


func set_username(new_name: String):
	$Name.text = new_name

func set_pick(pick_text: String):
	$Pick.text = pick_text

func set_cur_user():
	$Name.modulate = current_user_color

func set_picked():
	$Pick.modulate = picked_color
