extends Node2D
@onready var sfx_player = $AudioStreamPlayer2D

# Called when the node enters the scene tree for the first time.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D: # Always check for the player!
		var dialogue = get_tree().get_first_node_in_group("DialogueSystem")
		if dialogue:
			# 1. Start the dialogue
			dialogue.load_dialogue("res://Dialogue/rooftop1.json")
			
			# 2. Wait for the FINISHED signal 
			# Note: Ensure dialogue_finished is emitted in close_dialogue()
			await dialogue.dialogue_finished
			await get_tree().create_timer(0.5).timeout
			
			# --- SECOND CONVERSATION ---
			# We use the same 'dialogue' variable. 
			# Calling this will trigger a NEW 'dialogue_finished' signal later.
			dialogue.load_dialogue("res://Dialogue/rooftop2.json")
			await dialogue.dialogue_finished
		
			# 3. Play the audio
		if sfx_player:
			if sfx_player.stream:
				sfx_player.play()
				print("JUMPSCARE: Audio Playing")
				var tween = create_tween()
				tween.tween_property($CanvasModulate, "color", Color(0, 0, 0, 1), 1).set_trans(Tween.TRANS_CUBIC)
				await get_tree().create_timer(5).timeout
				get_tree().change_scene_to_file("res://Scenes/MemoryLane.tscn")
			else:
				print("Error: Audio node found but NO STREAM assigned.")
		else:
			print("Error: AudioStreamPlayer2D node is NULL.")
			
			
		
			
