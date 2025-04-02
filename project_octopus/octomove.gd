extends CharacterBody3D

const MAX_SPEED = 2
@onready var WORLD_NODE = get_node("../WorldEnvironment")
@onready var PLAYER = get_node("../Player")
@onready var MAX_STEP_HEIGHT = PLAYER.MAX_STEP_HEIGHT
var _snapped_to_stairs_last_frame := false;
var path = []
var nextGoalIndex = 0
var lastRecalc = 0

func _ready():
	await get_tree().create_timer(0.1).timeout # Make sure the generator has time to finish
	# Move the octopus down to the top of the procedural terrain
	position.y = (WORLD_NODE.getHeight(position.x, position.z) + 1)
	
	# Initial path planning
	_recalcPath()

func _recalcPath():
	# Ask the WORLD_NODE for a path to the player from current position
	path = WORLD_NODE.aStarNavigation(Vector2i(round(position.x),round(position.z)),Vector2i(round(PLAYER.position.x),round(PLAYER.position.z)))
	nextGoalIndex = 0

func _step_up(delta) -> bool:
	# Code adapted from youtube.com/watch?v=Tb-R3l0SQdc
	if not is_on_floor() and not _snapped_to_stairs_last_frame: 	return false
	# Find the direction we're moving in (x and z only)
	var expected_move_motion = self.velocity * Vector3(1,0,1) * delta
	# Find the position to test for collision: in front of the octopus and slightly up
	# We go up to get some clearance above; making sure there's nothing above in the way
	var step_pos_with_clearance = self.global_transform.translated(expected_move_motion + Vector3(0, MAX_STEP_HEIGHT * 2, 0))
	
	# Run a body_test_motion slightly above the pos we expect to move to, casting the tested motion down to find where the top of the next step is
	# Basically, we are making a copy of the player that should be above any possible step, then moving them down until we hit a step, so we know if and where that would happen
	var down_check_result = PhysicsTestMotionResult3D.new()
	if (_run_body_test_motion(step_pos_with_clearance, Vector3(0,-MAX_STEP_HEIGHT*2,0), down_check_result)
			and (down_check_result.get_collider().is_class("StaticBody3D") or down_check_result.get_collider().is_class("CSGShape3D"))):
		# Find how far to step up; the distance to the test point, plus the distance the tester could travel (which is negative, since it's down), relative to current position. Then extract only the y.
		var step_height = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - self.global_position).y
		# Final check to make sure the step height is valid
		# The step_height <= 0.01 "prevents some physics glitchiness"
		if step_height > MAX_STEP_HEIGHT or step_height <= 0.01 or (down_check_result.get_collision_point() - self.global_position).y > MAX_STEP_HEIGHT: return false
		# Make the final jump to new position
		self.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
		apply_floor_snap()
		_snapped_to_stairs_last_frame = true
		return true
	return false

func _run_body_test_motion(from: Transform3D, motion : Vector3, result = null) -> bool:
	# Code adapted from youtube.com/watch?v=Tb-R3l0SQdc
	# Wrapper for sending info to the PhysicsServer, asking it to test the result of a possible move
	if not result: result = PhysicsTestMotionResult3D.new()
	var params = PhysicsTestMotionParameters3D.new()
	params.from = from
	params.motion = motion
	return PhysicsServer3D.body_test_motion(self.get_rid(), params, result)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Once a second, recalculate a new path
	if (Time.get_ticks_msec() - lastRecalc > 1000):
		_recalcPath()

	# If there is a path
	if len(path) > 0:
		# If we've basically made it to the current waypoint, set the goal to the next one
		if (abs(path[nextGoalIndex].x - position.x) < MAX_SPEED or abs(path[nextGoalIndex].y - position.z) < MAX_SPEED):
			nextGoalIndex += 1
			if (nextGoalIndex > len(path)):
				_recalcPath()
		
		# Move in the appropriate direction
		velocity.x = MAX_SPEED * sign(path[nextGoalIndex].x - position.x)
		velocity.z = MAX_SPEED * sign(path[nextGoalIndex].y - position.z)
	
	rotation = PLAYER.rotation
	
	if not _step_up(delta):
		move_and_slide()
