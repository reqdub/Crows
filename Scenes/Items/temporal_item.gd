extends RigidBody2D

func _ready() -> void:
	await get_tree().create_timer(5.0).timeout
	self.queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Throwable"):
		body.destroy()
		self.destroy()

func destroy():
	$Sprite2D.visible = false
	$CPUParticles2D.emitting = true

func _on_cpu_particles_2d_finished() -> void:
	self.queue_free()
