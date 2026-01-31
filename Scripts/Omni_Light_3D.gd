extends OmniLight3D

@export var min_energy: float = 0.5
@export var max_energy: float = 4.0
@export var flicker_speed: float = 0.05 

@onready var mesh_instance = get_parent()

func _ready():
	flicker_loop()

func flicker_loop():
	while true:
		var target_energy = randf_range(min_energy, max_energy)
		
		light_energy = target_energy

		var mat = mesh_instance.get_active_material(0)
		if mat is StandardMaterial3D:
			mat.emission_energy_multiplier = target_energy

		await get_tree().create_timer(randf_range(0.01, flicker_speed)).timeout
