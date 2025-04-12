extends Camera3D

@onready var player: CharacterBody3D = $"../../.."
@onready var octopus_node: Node3D = $"../../../../Octopus"
@onready var target_node = get_parent().get_parent()
@export var camera_distance: float = 6.0
@export var rotation_speed: float = 5.5
@export var height_offset: float = 1.0
@export var octopus_look_weight: float = 0.3
@export var octopus_look_speed: float = 2.0
@export var focus_transition_speed: float = 3.0
@export var default_fov: float = 75.0
@export var focus_fov: float = 65.0

var target_rotation: float = 0.0
var current_position: Vector3
var looking_at_octopus: bool = false
var current_look_weight: float = 0.0
var target_look_weight: float = 0.0
var default_look_target: Vector3 = Vector3.ZERO
var current_fov: float
var reticle = load("res://Reticle.png")

func _ready() -> void:
	# Initialize FOV
	current_fov = default_fov
	fov = default_fov

func set_looking_at_octopus(look: bool) -> void:
	looking_at_octopus = look
	target_look_weight = 1.0 if look else 0.0

func _process(delta: float) -> void:
	if not target_node:
		return
	# Smoothly rotate the camera
	rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	# Apply the same rotation to the player but offset it correctly
	player.rotation.y = target_rotation + deg_to_rad(90)
	
	# Update camera position based on target position
	var target_pos = target_node.global_position
	target_pos.y += height_offset
	default_look_target = target_pos
	
	# Calculate new camera position
	var desired_position = target_pos + Vector3(camera_distance, 0, 0).rotated(Vector3.UP, target_rotation)
	current_position = current_position.lerp(desired_position, rotation_speed * delta)
	global_position = current_position
	
	# Smoothly transition the look weight
	current_look_weight = lerp(current_look_weight, target_look_weight, focus_transition_speed * delta)
	
	# Smoothly adjust FOV based on focus state
	var target_fov = default_fov
	if looking_at_octopus:
		target_fov = lerp(default_fov, focus_fov, current_look_weight)
		Input.set_custom_mouse_cursor(reticle, Input.CURSOR_ARROW)
	else:
		Input.set_custom_mouse_cursor(null)
	current_fov = lerp(current_fov, target_fov, focus_transition_speed * delta)
		
	fov = current_fov
	
	# Look at target or partially at octopus
	if current_look_weight > 0.01 and octopus_node != null:
		var octopus_pos = octopus_node.global_position
		octopus_pos.y += height_offset
		
		# Blend between the default look target and the octopus position
		var blended_target = default_look_target.lerp(octopus_pos, current_look_weight * octopus_look_weight)
		look_at(blended_target, Vector3.UP)
	else:
		# Default behavior - look at the player
		look_at(default_look_target)

# Handle Input Events
func _input(event: InputEvent) -> void:
	# Press Q to rotate left
	if Input.is_action_just_pressed("rotate_left"):  
		target_rotation = fmod(target_rotation + deg_to_rad(90), TAU)
	# Press E to rotate right
	elif Input.is_action_just_pressed("rotate_right"):  
		target_rotation = fmod(target_rotation - deg_to_rad(90), TAU)
