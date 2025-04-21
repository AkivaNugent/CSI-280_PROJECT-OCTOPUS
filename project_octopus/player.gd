extends CharacterBody3D

const SPEED = 3.0
const JUMP_VELOCITY = 4.5
const MAX_STEP_HEIGHT = 0.75
const SPRINT_VELOCITY = 2
@onready var player: CharacterBody3D = $"."
@onready var pivot: Node3D = $"Camera Origin"
#@export var sens = 0.5
var _snapped_to_stairs_last_frame := false;
@onready var animated_sprite_3d = $AnimatedSprite3D
@onready var animation_player = $AnimationPlayer
@onready var pos_text: Label = $"../Control/Pos Text"
var dir_facing: String
@onready var facing_text: Label = $"../Control/Facing Text"

# Health Variables
@export var maxHealth: float = 100
@export var currentHealth: float = 100
var regen: float = 5
@onready var health_bar: ProgressBar = $"../Control/Health Bar"

#Audio Variables
@onready var player_Walking_Audio = $"../AudioStreamPlayer_walking"
@onready var player_Running_Audio = $"../AudioStreamPlayer_running"

#Game Over Screen Variables
const GAMEOVER_SCREEN = preload("res://gameover_screen.tscn")
@onready var fade_anim_overlay = $"../Control/FadeOverlay"
@onready var is_dying = false
@onready var fade_time = 1.5
@onready var you_died_text = $"../Control/YouDied"
@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D

var lastTookDamage = 0

#Aiming and Cursor

# Animation Variables
var is_playing_attack_anim = false
var attack_timer: Timer

func _ready():
	currentHealth = maxHealth
  
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	you_died_text.visible = false
	
	# Create and configure attack animation timer
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.wait_time = 0.5  # Default time - adjust based on your actual animation length
	attack_timer.timeout.connect(on_attack_animation_timeout)
	add_child(attack_timer)
	
	# Reset attack animation flag at start
	is_playing_attack_anim = false
	
	await get_tree().create_timer(0.1).timeout # Make sure the generator has time to finish
	# Move the player down to the top of the procedural terrain
	position.y = (get_node("../WorldEnvironment").getHeight(position.x, position.z) + 1)
	

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
		# The step_height <= 0.001 "prevents some physics glitchiness"
		if step_height > MAX_STEP_HEIGHT or step_height <= 0.001 or (down_check_result.get_collision_point() - self.global_position).y > MAX_STEP_HEIGHT: return false
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
	# Game Over Fade Animation
	if is_dying:
		# Handle dying fade animation
		var current_alpha = fade_anim_overlay.color.a
		if current_alpha < 1.0:
			fade_anim_overlay.color.a += delta / fade_time / 3
			you_died_text.modulate.a = min(fade_anim_overlay.color.a * 1.5, 1.0)
			if fade_anim_overlay.color.a >= 1.0:
				# change to game over scene
				get_tree().change_scene_to_packed(GAMEOVER_SCREEN)
		return
		
	var ScreenColorer = get_tree().get_current_scene().get_node("CanvasLayer/ScreenColorer")
	# Draw the screen red if the player recently took damage
	if (Time.get_ticks_usec() - lastTookDamage < (1000000 / 2)):
		ScreenColorer.modulate = Color(1.0, 0.5, 0.5, 0.2)
		ScreenColorer.size = get_viewport().size
		
	else:
		ScreenColorer.modulate = Color(1.0, 1.0, 1.0, 0.0)
		
	pos_text.text = "X: " + str(round(position.x)) + " Y: "  + str(round(position.y)) + " Z: " + str(round(position.z))
	
	if rotation_degrees.y == 360:
		dir_facing = "North"
	if rotation_degrees.y == 90:
		dir_facing = "West"
	if rotation_degrees.y == 180:
		dir_facing = "South"
	if rotation_degrees.y == 270:
		dir_facing = "East"
	facing_text.text = "Facing " + dir_facing
	
	# Kill player for falling off map
	if position.y < 0:
		take_damage(9999)
		
	if currentHealth > maxHealth:
		currentHealth = maxHealth
	else:
		currentHealth += regen * delta
	health_bar.value = currentHealth
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor(): #or snapped to stairs?
		velocity.y = JUMP_VELOCITY
		is_jumping = true
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
		
		# Walking Sound Effect
		if !player_Walking_Audio.playing && !player_Running_Audio.playing:
			player_Walking_Audio.play()
		
		# Running Sound Effect and Sprint Mechanic
		if Input.is_action_pressed("sprint"):
			velocity.z *= SPRINT_VELOCITY
			velocity.x *= SPRINT_VELOCITY
			
			if !player_Running_Audio.playing:
				player_Running_Audio.play()
			if player_Walking_Audio.playing:
				player_Walking_Audio.stop()
		else:
			if player_Running_Audio.playing:
				player_Running_Audio.stop()
		
		# Get input direction in camera space for animation
		var raw_input_dir := Input.get_vector("left", "right", "up", "down")
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
		# Stop walking/running sounds when not moving
		if player_Walking_Audio.playing:
			player_Walking_Audio.stop()
		if player_Running_Audio.playing:
			player_Running_Audio.stop()
	
	# Put the StairsAheadRayCast (for step up) actually in front of the player
	# First, establish which direction relative to the player is worldspace positive X using their rotation
	var positiveX = Vector3(cos(deg_to_rad(rotation_degrees.y)),0,sin(deg_to_rad(rotation_degrees.y))) 
	# Then, find the direction of movement in worldspace
	var norm = velocity.normalized()
	# Use the positiveX vector to figure out what that velocity looks like relative to the player
	# Basically: if positive X is in the player's X axis, then map X to X and Z to Z, then consider the sign of positiveX.
	# If positive X is in the Z axis relative to the player, swap the variables before considering the sign
	if int(positiveX.x) != 0:
		$StairsAheadRayCast3D.position = Vector3(norm.x * positiveX.x, -0.1, norm.z * positiveX.x)
	else:
		$StairsAheadRayCast3D.position = Vector3(-norm.z * positiveX.z, -0.1, norm.x * positiveX.z)

	# Handle animations
	handle_animations(input_dir)

	if not _step_up(delta):
		move_and_slide()
		
func take_damage(amount):
	if (Time.get_ticks_usec() - lastTookDamage > (1000000 / 2)):
		currentHealth -= amount
		lastTookDamage = Time.get_ticks_usec()
		gpu_particles_3d.emitting = true
		if currentHealth <= 0 and !is_dying:
			# Start death fade sequence
			is_dying = true
			you_died_text.visible = true
			
			# Could Implement Death Sound/Song

# ------ ANIMATION SECTION START ------ #
# CHARACTER STATES
# ####
enum Direction {UP, DOWN, LEFT, RIGHT}
enum MovementState {STILL, RUNNING, JUMPING, FALLING}
enum ActionState {NORMAL, ATTACKING}

# ANIMATION VARIABLES
# ####
var current_direction = Direction.DOWN
var current_movement = MovementState.STILL
var current_action = ActionState.NORMAL
var raw_input_dir = Vector2.ZERO
var is_jumping = false
var on_floor_now = true
var was_on_the_floor_last_frame = true
var current_spirte_animation = ""
var current_player_animation = ""
var is_attacking = false
var inp_to_dir

# DRIVING FUNCTION
# ####
func handle_animations(input_direction: Vector2):
	# RESET STATES IF REQUIRED
	resetJump()
	
	# CURRENT-STATE SETTERS
	current_direction = setDirection(input_direction)
	current_movement = setMovmentState(input_direction)
	current_action = setActionState()
	
	# SET ANIMATIONS
	current_spirte_animation = applyDirection(current_direction)
	current_spirte_animation += applyMovmentState(current_movement)
	current_spirte_animation += applyActionState(current_action)
	
	current_player_animation = "player_animations/"
	current_player_animation += applyDirection(current_direction)
	current_player_animation += applyMovmentState(current_movement)
	current_player_animation += applyActionState(current_action)
	
	if "_atk" in current_spirte_animation:
		print(current_spirte_animation)
		print("PLAYER:" + current_player_animation)
	
	if !(is_playing_attack_anim and not "_atk" in current_spirte_animation):
		play_animation(current_spirte_animation, current_player_animation)
	
	# PREVIOUS FRAME UPDATES
	was_on_the_floor_last_frame = on_floor_now
	on_floor_now = is_on_floor()

# HELPER FUNCTIONS 
# ####
func resetJump():
	if on_floor_now && !was_on_the_floor_last_frame && is_jumping:
		is_jumping = false
		#print("STATE RESET --- landed from jump")

func setDirection(raw_inp_dir):
	if raw_inp_dir.length() > 0:
		if abs(raw_inp_dir.y) > abs(raw_inp_dir.x):
			inp_to_dir = Direction.UP if raw_inp_dir.y < 0 else Direction.DOWN
		else:
			inp_to_dir = Direction.LEFT if raw_inp_dir.x < 0 else Direction.RIGHT
	return inp_to_dir

func applyDirection(current_direction):
	var cardinality = "idle"
	match current_direction:
			Direction.UP:
				cardinality = "up"
			Direction.DOWN:
				cardinality = "down"
			Direction.LEFT:
				cardinality = "side"
			Direction.RIGHT:
				cardinality = "side"
	return cardinality
	
func setMovmentState(raw_input_dir):
	var motionValue
	if !is_on_floor():
		if is_jumping:
			motionValue = MovementState.JUMPING
		else:
			motionValue = MovementState.FALLING
	else:
		if raw_input_dir.length() > 0:
			motionValue = MovementState.RUNNING
		else:
			motionValue = MovementState.STILL
	return motionValue
	
func applyMovmentState(current_movement):
	var motionValue = ""
	
	match current_movement:
		MovementState.JUMPING:
			motionValue = "_jump"
		MovementState.RUNNING:
			motionValue = "_run"
		MovementState.FALLING:
			motionValue = "_run"
	
	return motionValue
	
func setActionState():
	var action = ActionState.NORMAL
	if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_left_mouse"):
		#print("ATTACKED")
		action = ActionState.ATTACKING
	
	return action
	
func applyActionState(current_action):
	var action
	
	match current_action:
		ActionState.NORMAL:
			action = ""
		ActionState.ATTACKING:
			action = "_atk"
			
	return action
	
func flipSpriteForDirection(direction):
	var weapons_inventory = get_node_or_null("WeaponsInventory")
	
	if direction == Direction.LEFT or direction == Direction.DOWN:
		animated_sprite_3d.scale.x = -abs(animated_sprite_3d.scale.x)
		weapons_inventory.scale.x = -1
			
	elif direction == Direction.RIGHT:
		animated_sprite_3d.scale.x = abs(animated_sprite_3d.scale.x)
		weapons_inventory.scale.x = 1
		
func play_animation(sprite_anim: String, player_anim: String):
	animated_sprite_3d.play(sprite_anim)
	animation_player.play(player_anim)
	flipSpriteForDirection(current_direction)
	
	if "_atk" in sprite_anim:
		is_playing_attack_anim = true
		attack_timer.wait_time = .5
			
		if attack_timer.time_left > 0:
			attack_timer.stop()
			
		attack_timer.start()

func on_attack_animation_timeout():
	is_playing_attack_anim = false
	print("ATK ENDED")
# ------ ANIMATION SECTION END ------ #
