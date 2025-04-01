extends Node3D

var projectileScene = load("res://projectile.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event) -> void:
	if event is InputEventMouseButton and event.button_index == 1:
			#Code from https://docs.godotengine.org/en/4.0/tutorials/physics/ray-casting.html#raycast-query (final box)
			var space_state = get_world_3d().direct_space_state
			var cam = get_viewport().get_camera_3d()
			var mousepos = get_viewport().get_mouse_position()

			const RAY_LENGTH = 1000;
			var origin = cam.project_ray_origin(mousepos)
			var end = origin + cam.project_ray_normal(mousepos) * RAY_LENGTH
			var query = PhysicsRayQueryParameters3D.create(origin, end)
			query.collide_with_areas = true

			var result = space_state.intersect_ray(query)
			
			var projectile = projectileScene.instantiate()
			get_tree().get_root().add_child(projectile)
			if result != {}:
				var targ = (Vector3(result["position"]) - global_position).normalized() * 5
				projectile.global_position = global_position
				projectile.velocity = targ
				print(projectile.velocity)
