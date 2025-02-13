extends Node3D
@export var day_length: float
@export var night_length: float
@export var env: WorldEnvironment

var time_passed: float = 0.0
var is_day: bool = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_passed += delta
	var cycleDuration = day_length if is_day else night_length
	var progress = time_passed / cycleDuration
	
	if env:
		if is_day: # night to day
			env.environment.adjustment_brightness = lerp(0.2, 1.0, progress)
		else: # day to night
			env.environment.adjustment_brightness = lerp(1.0, 0.2, progress)
	
	# switches which cycle to use
	if time_passed >= cycleDuration:
		is_day = !is_day
		time_passed = 0.0
