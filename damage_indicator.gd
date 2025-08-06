extends RigidBody2D

func _ready():
	var random_x_impulse = randi_range(-400, 400)
	var random_y_impulse = randi_range(-100, -300)
	apply_impulse(Vector2(random_x_impulse, random_y_impulse), Vector2.ZERO)
	await get_tree().create_timer(1.0).timeout
	self.queue_free()

func damage_amount(_amount):
	$Label.set_text(str(_amount))
