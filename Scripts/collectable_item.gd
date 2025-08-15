extends RigidBody2D

class_name droppable_item

var collect_area
var is_collected = false
var direction = Vector2(0,0)
var speed = 1000
var item_texture
var item_name
var item_amount

func _ready() -> void:
	var random_x_impulse = randi_range(-5, -10)
	var random_y_impulse = randi_range(5, -10)
	apply_impulse(Vector2(random_x_impulse, random_y_impulse), Vector2.ZERO)
	$Sprite2D.texture = item_texture
	$Timer.start()

func _on_body_entered(_body: Node) -> void:
	AudioManager.play_sound(SoundCache.coin_flip_sound)

func _physics_process(delta: float) -> void:
	if not is_collected: return
	if collect_area != null:
		global_position -= (global_position.direction_to(collect_area.global_position).normalized()) * -1 * speed * delta

func set_item(_item_name : String, _item_amount : int = 1, custom_collector = null):
	collect_area = custom_collector
	item_texture = load("res://Sprites/Items/" + _item_name + ".png")
	item_name = _item_name
	item_amount = _item_amount

func destroy():
	$Timer.stop()
	self.queue_free()

func _on_timer_timeout() -> void:
	gravity_scale = 0.0
	is_collected = true
	await get_tree().create_timer(4.0).timeout
	self.queue_free()
