extends RigidBody2D

class_name battle_text_indicator

func _ready():
	var random_x_impulse = randi_range(-400, 400)
	var random_y_impulse = randi_range(-100, -300)
	apply_impulse(Vector2(random_x_impulse, random_y_impulse), Vector2.ZERO)
	await get_tree().create_timer(1.0).timeout
	self.queue_free()

func setup(text : String, color : Color):
	$Label.set_text(text)
	$Label.add_theme_color_override("font_color", color)
