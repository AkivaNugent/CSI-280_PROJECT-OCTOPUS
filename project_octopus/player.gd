extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MAX_STEP_HEIGHT = 0.75
@onready var player: CharacterBody3D = $"."
@onready var pivot: Node3D = $"Camera Origin"
#@export var sens = 0.5
var _snapped_to_stairs_last_frame := false;
@onready var animated_sprite_2d = $AnimatedSprite3D
@export var posText: Label
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

#func _input(event):
	#if event is InputEventMouseMotion:
		#rotate_y(deg_to_rad(-event.relative.x * sens))
		#pivot.rotate_x(deg_to_rad(-event.relative.y * sens))
		#pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-90), deg_to_rad(45))

func _step_up(delta) -> bool:
	# Code adapted from youtube.com/watch?v=Tb-R3l0SQdc
	if not is_on_floor() and not _snapped_to_stairs_last_frame: return false
	# Find the direction we're moving in (x and z only)
	var expected_move_motion = self.velocity * Vector3(1,0,1) * delta
	# Find the position to test for collision: in front of the player and slightly up
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

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor(): #or snapped to stairs?
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	# Get camera's rotation basis
	var camera_transform := pivot.global_transform.basis  
	var camera_forward := camera_transform.z.normalized() 
	var camera_right := camera_transform.x.normalized()  
	
	# Calculate movement direction relative to the camera's rotation
	var direction := (camera_right * input_dir.x + camera_forward * input_dir.y).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Get input direction in camera space
		var input_dir2 := Input.get_vector("left", "right", "up", "down")
		
		# Play animation based on raw input direction
		if input_dir2.length() > 0:
			if abs(input_dir2.y) > abs(input_dir2.x):
				if input_dir2.y < 0:
					animated_sprite_2d.play("move_forward")
				else:
					animated_sprite_2d.play("move_backward")
			else:
				if input_dir2.x < 0:
					animated_sprite_2d.play("move_left")
				else:
					animated_sprite_2d.play("move_right")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		animated_sprite_2d.play("idle")
		
	if posText:
		posText.text = "X: " + str(round(position.x)) + " Y: " + str(round(position.y)) + " Z: " + str(round(position.z))

	if not _step_up(delta):
		move_and_slide()
