extends CharacterBody3D

var damage : float
var maxRange : float
var startPos;
var PLAYER;

func _physics_process(delta: float) -> void:
	rotation = PLAYER.rotation
	
	move_and_slide()
	
	if global_position.distance_to(startPos) > maxRange:
		queue_free()
		
	var collided = false
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var body = collision.get_collider()
		collided = true
		if body.has_method("projectile_hit"):
			body.projectile_hit(damage)
	if collided:
		queue_free()
