extends Node2D
@onready var sfx_player = $AudioStreamPlayer2D

# Called when the node enters the scene tree for the first time.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	var dialogue = get_tree().get_first_node_in_group("DialogueSystem")
	if dialogue:
		dialogue.load_dialogue("res://Dialogue/rooftop2.json")
		await dialogue.dialogue_finished
		if sfx_player.stream:
			sfx_player.play()
			print("JUMPSCARE: Audio Playing")
		else:
			push_error("JumpscareSFX is missing an AudioStream!")
		
			
