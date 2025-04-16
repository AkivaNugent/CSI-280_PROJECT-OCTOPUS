extends Node3D

var mob = preload("res://octopus.tscn")
@onready var rand=RandomNumberGenerator.new()

func _ready():
	while(true):
		spawn();
		await get_tree().create_timer(1.0).timeout
	
func spawn():
	var xLoc = rand.randi_range(1,10)
	var yLoc = rand.randi_range(1,10)
	var mob = preload("res://octopus.tscn")
	var m = mob.instantiate()
	add_child(m)
	m.global_position = Vector3i(xLoc,220,yLoc)
	
	
	
