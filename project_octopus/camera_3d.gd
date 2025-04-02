extends Camera3D

@onready var player: CharacterBody3D = $"../../.."
@onready var target_node = get_parent().get_parent()
@export var camera_distance: float = 6.0
@export var rotation_speed: float = 5.5
@export var height_offset: float = 1.0

var target_rotation: float = 0.0
var current_position: Vector3

func _ready() -> void:
	pass

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
	
	# Calculate new camera position
	var desired_position = target_pos + Vector3(camera_distance, 0, 0).rotated(Vector3.UP, target_rotation)
	current_position = current_position.lerp(desired_position, rotation_speed * delta)
	global_position = current_position
	# Make the camera look at the target
	look_at(target_pos)

# Handle Input Events
func _input(event: InputEvent) -> void:
	# Press Q to rotate left
	if Input.is_key_pressed(KEY_Q):  
		target_rotation = fmod(target_rotation + deg_to_rad(90), TAU)
	# Press E to rotate right
	elif Input.is_key_pressed(KEY_E):  
		target_rotation = fmod(target_rotation - deg_to_rad(90), TAU)
