extends Node3D

@export var day_length: float = 150.0  # Duration of the day in seconds
@export var night_length: float = 150.0  # Duration of the night in seconds
@export var world_environment: WorldEnvironment
@export var day_text: Label

var overall_progress = 0.5

var time_passed: float = 0.0
var is_day: bool = false
var current_day: int = 1


func _process(delta):
	time_passed += delta
	
	var cycle_duration = day_length if is_day else night_length
	var progress = time_passed / cycle_duration
	overall_progress = (time_passed + (day_length * int(!is_day))) / (day_length + night_length)
	
	var hour = float(int(overall_progress * 24 * 10)) / 10 #round to first decimal place
	day_text.text = "Day " + str(current_day) + " Hour " + str(hour)
	
	if world_environment:
		var env = world_environment.environment
		if env:
			# Interpolate brightness for smooth transition
			if is_day:
				env.adjustment_brightness = lerp(0.25, 1.0, progress)  # Night to Day
			else:
				env.adjustment_brightness = lerp(1.0, 0.25, progress)  # Day to Night
				
	
	# switches what cycle to use
	if time_passed >= cycle_duration:
		if !is_day:
			current_day += 1
		is_day = !is_day
		time_passed = 0.0
