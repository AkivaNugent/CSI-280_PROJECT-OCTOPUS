extends CharacterBody3D


const SPEED = 3.0
const JUMP_VELOCITY = 4.5
const MAX_STEP_HEIGHT = 0.75
const SPRINT_VELOCITY = 2
@onready var player: CharacterBody3D = $"."
@export var player_id := 1:
	set(id):
		player_id = id
		%InputSynchronizer.set_multiplayer_authority(id)
@onready var pivot: Node3D = $"Camera Origin"
#@export var sens = 0.5
var _snapped_to_stairs_last_frame := false;
@onready var animated_sprite_2d = $AnimatedSprite3D
@onready var pos_text: Label = $"../../Control/Pos Text"
var dir_facing: String
@onready var facing_text: Label = $"../../Control/Facing Text"
#Audio Variables
@onready var player_Walking_Audio = $"../../AudioStreamPlayer_walking"
@onready var player_Running_Audio = $"../../AudioStreamPlayer_running"

func _ready():
	print("Player instance path: ", get_path())
	print("Parent node: ", get_parent().name)
	print("Available nodes at parent level:")
	for child in get_parent().get_children():
		print("- ", child.name)
	print("Available nodes two levels up:")
	if get_parent() and get_parent().get_parent():
		for child in get_parent().get_parent().get_children():
			print("- ", child.name)

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

func _apply_animations(delta):
	# Animation based on input direction
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
		animated_sprite_2d.play("idle")
func _apply_movement_from_input(delta):
	# Get the input direction and handle the movement/deceleration
	var input_dir: Vector2 = %InputSynchronizer.input_direction #Input synchronizer is a multiplayer synchronizer we reference to get the data as its being pressed
	# Get camera's rotation basis
	var camera_transform := pivot.global_transform.basis  
	var camera_forward := camera_transform.z.normalized() 
	var camera_right := camera_transform.x.normalized()  
	
	# Calculate movement direction relative to the camera's rotation
	var direction := (camera_right * input_dir.x + camera_forward * input_dir.y).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Walking Sound Effect
		if !player_Walking_Audio.playing && !player_Running_Audio.playing:
			player_Walking_Audio.play()
		
		# Running Sound Effect and Sprint Mechanic
		if Input.is_action_pressed("sprint"):
			velocity.z *= SPRINT_VELOCITY
			velocity.x *= SPRINT_VELOCITY
			
		if !player_Running_Audio.playing:
			player_Running_Audio.play()


func _physics_process(delta):
	if multiplayer.is_server():
		_apply_movement_from_input(delta)
