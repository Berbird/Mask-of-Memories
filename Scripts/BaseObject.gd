extends StaticBody2D

@export var object_id: String = ""
@export var is_interactable: bool = true

@export var interaction_data: Dictionary = {
	"default": {
		"text": "...",
		"name": "???",
		"portrait": ""
	}
}

func _ready():
	if is_interactable and has_node("Area2D"):
		var area = $Area2D
		area.set_meta("interaction_data", interaction_data)
