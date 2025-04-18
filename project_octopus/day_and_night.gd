extends Node3D

@export var day_length: float = 60.0  # Duration of the day in seconds
@export var night_length: float = 60.0  # Duration of the night in seconds
@export var world_environment: WorldEnvironment
@export var day_text: Label

var time_passed: float = 0.0
var is_day: bool = true
var current_day: int = 1

func _ready() -> void:
	time_passed += day_length / 2

func _process(delta):
	day_text.text = "Day " + str(current_day)
	time_passed += delta
	
	var cycle_duration = day_length if is_day else night_length
	var progress = time_passed / cycle_duration
	
	if world_environment:
		var env = world_environment.environment
		if env:
			# Interpolate brightness for smooth transition
			if is_day:
				env.adjustment_brightness = lerp(0.1, 1.0, progress)  # Night to Day
			else:
				env.adjustment_brightness = lerp(1.0, 0.1, progress)  # Day to Night
				
	
	# switches what cycle to use
	if time_passed >= cycle_duration:
		if !is_day:
			current_day += 1
		is_day = !is_day
		time_passed = 0.0
