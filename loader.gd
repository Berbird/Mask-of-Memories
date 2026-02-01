# DOĞRU KULLANIM
extends Node2D

func _ready():
	# Artık güvenle çağırabilirsin
	DialogueSystem.load_dialogue("res://Dialogue/park_scene.json")
