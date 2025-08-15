extends RigidBody2D

class_name non_droppable_item

var collect_area = null
var direction = Vector2(0,0)
var speed = 1000

func _ready() -> void:
	var random_x_impulse = randi_range(-5, -10)
	var random_y_impulse = randi_range(5, -10)
	apply_impulse(Vector2(random_x_impulse, random_y_impulse), Vector2.ZERO)
	$Timer.start()

func _on_body_entered(_body: Node) -> void:
	pass
	#AudioManager.play_sound(SoundCache.coin_flip_sound)

func set_item(item_name : String, _custom_collector = null):
	$Sprite2D.texture = load("res://Sprites/Items/" + item_name + ".png")

func destroy():
	$Timer.stop()
	self.queue_free()

func _on_timer_timeout() -> void:
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	gravity_scale = 0.0
	await get_tree().create_timer(4.0).timeout
	self.queue_free()
