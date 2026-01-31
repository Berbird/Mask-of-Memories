extends Node

var is_night = true

func _ready():
	# Because this is an Autoload, it runs the moment the game starts.
	# We call our own function to load Trial 1.
	change_perspective("res://Scenes/Trial_1.tscn")
	
	# Wait for the scene to actually land in the tree
	await get_tree().process_frame
	
	# Find the DialogueSystem (assuming it's a child of this node or the root)
	var dialogue = get_tree().root.find_child("DialogueSystem", true, false)
	if dialogue:
		dialogue.start_dialogue("Welcome to the game.", "System")

func change_perspective(new_scene_path: String):
	# 'self' is the Main node in your case
	# 1. Clear current children (like an old trial or basement)
	for child in get_children():
		if child.name != "DialogueSystem": 
			child.queue_free()
			
	# 2. Instantiate and add the new 2D trial
	var next_level = load(new_scene_path).instantiate()
	add_child(next_level)
