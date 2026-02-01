extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var dialogue = get_tree().get_first_node_in_group("DialogueSystem")
	if dialogue:
		dialogue.load_dialogue("res://Dialogue/park1.json")
		await dialogue.dialogue_finished


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	var dialogue = get_tree().get_first_node_in_group("DialogueSystem")
	if dialogue:
		dialogue.load_dialogue("res://Dialogue/park2.json")
		await dialogue.dialogue_finished
		get_tree().change_scene_to_file("res://Scenes/MemoryLane.tscn")
