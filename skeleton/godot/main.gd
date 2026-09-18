extends Node
#
# Verifies the skeleton extension loaded and works: a property read and write,
# and _process actually running (the rotation is set from PureBasic).

func _ready() -> void:
	print("=== skeleton extension ===")
	var s := Spinner.new()
	print("Spinner: class=", s.get_class(), " speed=", s.speed)
	s.speed = 2.0
	add_child(s)
	for i in 10:
		await get_tree().process_frame
	print("after 10 frames: rotation=", s.rotation, " speed=", s.speed)
	s.speed = 5.0
	print("speed after write: ", s.speed)
	print("=== skeleton done ===")
	get_tree().quit()
