extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func change_perspective(new_scene_path: String):
	# 1. Remove the 3D Basement (It disappears entirely)
	if get_child_count() > 0:
		var current = get_child(0)
		current.queue_free() 
			# 2. Load the 2D Trial (The screen is now 2D)
		var next_level = load(new_scene_path).instantiate()
		add_child(next_level)
