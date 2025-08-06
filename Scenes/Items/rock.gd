extends RigidBody2D

enum type {
	ROCK
}

var item_type = type.ROCK
var throw_strength : float = 0.0
var base_damage : int = randi_range(5, 5)
var is_damage_dealt : bool = false
@onready var particles = load("res://on_throwable_destroy_particles.tscn")
@onready var particles_world_node = get_node("/root/World/Particles")

func _ready() -> void:
	match item_type:
		type.ROCK:
			$Sprite2D.texture = load("res://Sprites/Items/Rock1.png")
	var direction = (global_position - get_global_mouse_position()).normalized()
	var impulse = direction * -2000 * throw_strength
	self.apply_impulse(impulse, Vector2.ZERO)
	self.angular_velocity = randf_range(2, 10)

func deal_damage() -> int:
	if is_damage_dealt : return -1
	return int(base_damage * throw_strength)

func destroy():
	var particles_instance = particles.instantiate()
	particles_instance.global_position = self.global_position
	particles_world_node.add_child(particles_instance)
	$DestroyTimer.stop()
	self.queue_free()

func set_type(throwable_type):
	item_type = throwable_type

func _on_deactivate_timer_timeout() -> void:
	self.contact_monitor = false

func _on_destroy_timer_timeout() -> void:
	self.queue_free()

func disable():
	is_damage_dealt = true
