extends Node

class_name PathSplit

func _enter_tree():
	for child in get_children():
		child.add_to_group("PathBranch")
