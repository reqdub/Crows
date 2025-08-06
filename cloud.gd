extends Sprite2D

var direction : Vector2
var speed : float

func _ready() -> void:
	direction = global_position.direction_to(direction).normalized()
	var random_scale = randf_range(0.5, 1.2)
	scale = Vector2(random_scale, random_scale)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_timer_timeout() -> void:
	self.queue_free()
