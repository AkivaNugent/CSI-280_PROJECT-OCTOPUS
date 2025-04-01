extends CharacterBody3D

func _physics_process(delta: float) -> void:
	move_and_slide()
	var collided = false
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var body = collision.get_collider()
		collided = true
		print(body)
	if collided:
		queue_free()
