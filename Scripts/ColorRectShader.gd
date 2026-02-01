@tool
extends ColorRect

@export var scene_palette: Texture2D:
	set(value):
		scene_palette = value
		_update_shader()

func _ready():
	_update_shader()

func _update_shader():
	var mat = material as ShaderMaterial
	if mat and scene_palette:
		mat.set_shader_parameter("palette_tex", scene_palette)
