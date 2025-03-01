extends ParallaxBackground

var scrollSpeed : Vector2 = Vector2(20, 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	scroll_offset += scrollSpeed * delta
