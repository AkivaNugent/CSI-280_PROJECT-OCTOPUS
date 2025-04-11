extends Node3D

@onready var mob = preload("res://octopus.tscn")
@onready var rand=RandomNumberGenerator.new()

func _ready():
	while(true):
		spawn();
		await get_tree().create_timer(5.0).timeout
	
func spawn():
	var m = mob.instantiate()
	var rand_num = rand.randi_range(0,5)
	#m.global_position = Vector3i(rand_num,rand_num,75)
	add_child(m)
	
	
