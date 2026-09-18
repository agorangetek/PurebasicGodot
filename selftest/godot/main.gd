extends Node
# The extension does its work in its SCENE-level initialize callback, before
# this runs, and prints its report to Godot's log.
func _ready() -> void:
	get_tree().quit()
