extends Node

var is_dialogue_active = false
var can_interact = true

var _story_flags: Dictionary = {}

func set_flag(flag_name: String, value: bool) -> void:
	_story_flags[flag_name] = value

func get_flag(flag_name: String) -> bool:
	return _story_flags.get(flag_name, false)

func resolve_interaction(interaction_data: Dictionary) -> Dictionary:
	for key in interaction_data:
		if key == "default":
			continue
			
		var entry = interaction_data[key]
		if entry.has("condition"):
			if check_conditions(entry["condition"]):
				return entry
	
	if interaction_data.has("default"):
		return interaction_data["default"]
		
	return {}

func check_conditions(requirements: Dictionary) -> bool:
	for flag in requirements:
		var required_value = requirements[flag]
		if get_flag(flag) != required_value:
			return false
	return true
