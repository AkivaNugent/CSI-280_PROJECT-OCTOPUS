extends CharacterBody3D

@onready var WORLD_NODE = get_node("../WorldEnvironment")
@onready var PLAYER = get_node("../Player")
@onready var MAX_STEP_HEIGHT = PLAYER.MAX_STEP_HEIGHT
@onready var animated_sprite3d = $AnimatedSprite3D
@onready var playerCamera = $"../Player/Camera Origin/SpringArm3D/Camera3D"
var _snapped_to_stairs_last_frame := false;
var path = []
var nextGoalIndex = 0
var lastRecalc = 0
var focus_transition_timer := 0.0
var target_focus_state := false
const FOCUS_TRANSITION_DELAY := 0.3 
var is_mouse_in_area := false
var hover_check_timer := 0.0
const HOVER_CHECK_INTERVAL := 0.1 
var lastTookDamage = 0
@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D

@export var max_health : int
var current_health

var octoTracker;

const MAX_PATHING_RANGE = 10

@export var damage : int
@export var speed : float

func _ready():
	await get_tree().create_timer(0.1).timeout # Make sure the generator has time to finish
	# Move the octopus down to the top of the procedural terrain
	position.y = (WORLD_NODE.getHeight(position.x, position.z) + 10)

	# Initial path planning
	_recalcPath()
	
	current_health = max_health

func _recalcPath():
	# Three times a second, recalculate a new path
	# For every ten tiles between the player and the octopus, give another 0.2 seconds between calculations
	var distanceToPlayer = position.distance_to(PLAYER.position)
	const usecToSec = 1000000
	var nextRecalc = (usecToSec / 3) + ((usecToSec / 5) * (distanceToPlayer / 10))
	
	# Return if too early
	if (Time.get_ticks_usec() - lastRecalc < nextRecalc):
		return
	
	var targPosition = position
	# Only path direct to player if they're close. Otherwise, approximate by pathing to the nearest point to the player on a circle radius MAX_PATHING_RANGE
	if distanceToPlayer < MAX_PATHING_RANGE:
		targPosition = PLAYER.position
	else:
		var relativePosition = PLAYER.position - position
		targPosition = (relativePosition / relativePosition.length()) * MAX_PATHING_RANGE
		targPosition = position + targPosition
		
	# Ask the WORLD_NODE for a path to the target position from current position
	path = WORLD_NODE.aStarNavigation(Vector2i(round(position.x),round(position.z)),Vector2i(round(targPosition.x),round(targPosition.z)))
	nextGoalIndex = 0
	
	lastRecalc = Time.get_ticks_usec()

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
	if (position.y < 0):
		_die()
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Draw the octopus red if it recently took damage
	if (Time.get_ticks_usec() - lastTookDamage < (1000000 / 2)):
		$AnimatedSprite3D.modulate = Color(1.0, 0.5, 0.5, 1.0)
	else:
		$AnimatedSprite3D.modulate = Color.WHITE

	# Delays between real pathing attempts handled in function
	_recalcPath()

	# If there is a path
	if len(path) > nextGoalIndex:
		# Move in the appropriate directiongit 
		velocity.x = speed * sign(path[nextGoalIndex].x - position.x)
		velocity.z = speed * sign(path[nextGoalIndex].y - position.z)
		
		# If we've basically made it to the current waypoint, set the goal to the next one
		if (abs(path[nextGoalIndex].x - position.x) < speed or abs(path[nextGoalIndex].y - position.z) < speed):
			nextGoalIndex += 1

	rotation = PLAYER.rotation
	animated_sprite3d.play("default")

	if not _step_up(delta):
		move_and_slide()
	
	#Octopus collision handling
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var body = collision.get_collider()
		if body.has_method("take_damage"): #Should only be player
			body.take_damage(damage)
		
# Handle smooth focus transitions
	if focus_transition_timer > 0:
		focus_transition_timer -= delta
		if focus_transition_timer <= 0:
			playerCamera.set_looking_at_octopus(target_focus_state)

	# Regularly check hover state to improve reliability
	hover_check_timer -= delta
	if hover_check_timer <= 0:
		hover_check_timer = HOVER_CHECK_INTERVAL
		var is_hovering = _is_mouse_over_octopus()
		
		if is_hovering and !target_focus_state:
			is_mouse_in_area = true
			target_focus_state = true
			focus_transition_timer = FOCUS_TRANSITION_DELAY
		elif !is_hovering and target_focus_state and is_mouse_in_area:
			is_mouse_in_area = false
			target_focus_state = false
			focus_transition_timer = FOCUS_TRANSITION_DELAY


# Hovering Octopus
# *Need outline*
func _on_mouse_entered() -> void:
	is_mouse_in_area = true
	target_focus_state = true
	focus_transition_timer = FOCUS_TRANSITION_DELAY

func _on_mouse_exited() -> void:
	# Only exit focus if we're truly outside the area
	# This prevents flickering when camera moves
	if !_is_mouse_over_octopus():
		is_mouse_in_area = false
		target_focus_state = false
		focus_transition_timer = FOCUS_TRANSITION_DELAY

# Check if mouse is over octopus with a larger detection area
func _is_mouse_over_octopus() -> bool:
	# Get octopus screen position
	var camera = get_viewport().get_camera_3d()
	if !camera:
		return false

	# Check if octopus is visible on screen first
	var octopus_pos = camera.unproject_position(global_position)
	var viewport_rect = get_viewport().get_visible_rect()
	
	# If octopus is not on screen, return false
	if !viewport_rect.has_point(octopus_pos):
		return false
	
	var mouse_pos = get_viewport().get_mouse_position()

	# Adjust detection radius based on distance from camera
	var distance_to_camera = global_position.distance_to(camera.global_position)
	var base_radius = 100.0
	var scaled_radius = base_radius * (10.0 / max(distance_to_camera, 1.0))
	
	# Check if mouse is within this area
	return octopus_pos.distance_to(mouse_pos) < scaled_radius

func projectile_hit(amount) -> void:
	current_health -= amount
	lastTookDamage = Time.get_ticks_usec() 
	gpu_particles_3d.emitting = true
	if current_health <= 0:
		_die()

func _die() -> void:
	octoTracker.live_octos.erase(self)
	queue_free()
