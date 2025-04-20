extends Node3D

@onready var WORLD_NODE = get_node("WorldEnvironment")
@onready var TIME_NODE = get_node("Day and night")
var mob = preload("res://octopus.tscn")
@onready var rand=RandomNumberGenerator.new()
var live_octos = []
var waiting_octos = 2

@export var MIN_TIME_TO_SPAWN = 0.5
@export var MAX_TIME_TO_SPAWN = 15

const MAX_ENEMIES = 20

func _ready():
	randomize()
	while(true):		
		# Spawn an octo. If there are too many, hold them and spawn them as soon as possible.
		waiting_octos += 1
		for x in range(waiting_octos):
			if len(live_octos) < MAX_ENEMIES:
				spawn()
				waiting_octos -= 1
			else:
				break
		
		# Sin function with a peak at 0.5 (half of the day, where the game starts) and a min at 1 and 0, minimum MIN_TIME, maximum MAX_TIME
		var time_to_next = ((MAX_TIME_TO_SPAWN + MIN_TIME_TO_SPAWN) / 2) - (sin(2 * PI * (TIME_NODE.overall_progress + 0.25)) * ((MAX_TIME_TO_SPAWN - MIN_TIME_TO_SPAWN) / 2))
		#print(TIME_NODE.overall_progress, ", ", time_to_next)
		await get_tree().create_timer(time_to_next).timeout
	
func spawn():
	var angle = deg_to_rad(rand.randi_range(0,360))
	var xLoc = cos(angle) * (WORLD_NODE.MAP_RAD - 2)
	var yLoc = sin(angle) * (WORLD_NODE.MAP_RAD - 2)
	print("SPAWN " + str(xLoc) + ", " + str(yLoc))
	var m = mob.instantiate()
	add_child(m)
	live_octos.append(m)
	m.octoTracker = self
	m.global_position = Vector3i(xLoc,220,yLoc)
	m.speed = 2
	m.max_health = 100
	m.damage = 25
