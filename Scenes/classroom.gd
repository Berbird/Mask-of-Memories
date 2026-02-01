extends Node2D
var is_inside_trigger = false



func _process(_delta: float) -> void:
	# Checks every frame if the player is inside AND just pressed Space
	if is_inside_trigger and Input.is_action_just_pressed("ui_accept"):
		trigger_interaction()

func trigger_interaction():
	var dialogue = get_tree().get_first_node_in_group("DialogueSystem")
	if dialogue:
		dialogue.load_dialogue("res://Dialogue/classroom_dialogue.json")
		await dialogue.dialogue_finished
		get_tree().change_scene_to_file("res://Scenes/MemoryLane.tscn")


func _on_area_2d_body_entered(body: Node2D) -> void:
	trigger_interaction()
	
