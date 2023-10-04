extends CPUParticles2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if emitting:
		await get_tree().create_timer(lifetime).timeout
		queue_free()
