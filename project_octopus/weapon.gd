extends Node3D

##damage per hit
@export var damage : float
##maximum tiles travelled
@export var range : float
##tiles per second
@export var projectileSpeed : float
##time per shot
@export var fireRate : float
@export var weaponSpritePath : String
@export var projectileSpritePath : String

var lastShotTime = 0
var projectileScene = load("res://projectile.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.texture = load(weaponSpritePath)

func _process(delta) -> void:
	if Input.is_mouse_button_pressed(1) and float(Time.get_ticks_msec() - lastShotTime) / 1000 > fireRate:
		lastShotTime = Time.get_ticks_msec()
		#Code from https://docs.godotengine.org/en/4.0/tutorials/physics/ray-casting.html#raycast-query (final box)
		var space_state = get_world_3d().direct_space_state
		var cam = get_viewport().get_camera_3d()
		var mousepos = get_viewport().get_mouse_position()

		var origin = cam.project_ray_origin(mousepos)
		var end = origin + cam.project_ray_normal(mousepos) * origin.length() * range * 10
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = true

		var result = space_state.intersect_ray(query)
		
		#Back to original stuff
		#If raycast hit something
		if result != {}:
			#Create a projectile as a child of the scene
			var projectile = projectileScene.instantiate()
			get_tree().get_root().add_child(projectile)
			
			#Fire it in the direction of the hit point (plus 0.25 on the y)
			#(subtracting vectors gives direction between, and normalization makes the length of the new vector 1, which we then multiply by speed)
			var targ = (Vector3(result["position"]) + Vector3(0,0.25,0) - global_position).normalized() * projectileSpeed
			
			#Set a bunch of properties from our properties
			projectile.global_position = global_position
			projectile.startPos = global_position
			projectile.velocity = targ
			projectile.damage = damage
			projectile.maxRange = range
			projectile.get_node("Sprite3D").texture = load(projectileSpritePath)
			projectile.PLAYER = get_node("../../../../Player")
