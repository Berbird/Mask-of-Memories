extends Node2D
var is_inside_trigger = false


func trigger_interaction():
	var dialogue = get_tree().get_first_node_in_group("DialogueSystem")
	if dialogue:
		dialogue.load_dialogue("res://Dialogue/classroom_dialogue.json")
		await dialogue.dialogue_finished


func _on_area_2d_body_entered(body: Node2D) -> void:
	trigger_interaction()
	
