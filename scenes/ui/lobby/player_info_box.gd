extends HBoxContainer

class_name LobbyPlayerInfoBox

func _enter_tree():
	resize()

func resize():
	var c: MarginContainer = get_parent().get_parent()
	var g: GridContainer = get_parent()
	custom_minimum_size.x = floor((c.size.x - c.get("theme_override_constants/margin_right") - c.get("theme_override_constants/margin_left") - get("theme_override_constants/separation") - g.get("theme_override_constants/h_separation")) / 2)
