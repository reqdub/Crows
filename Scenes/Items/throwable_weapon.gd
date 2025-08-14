extends RigidBody2D

@onready var particles = load("res://Scenes/on_throwable_destroy_particles.tscn")
@onready var particles_world_node = get_node("/root/World/Particles")

var throw_strength : float = 0.0
var base_player_damage
var min_weapon_damage : int
var max_weapon_damage : int
var is_damage_dealt : bool = false
var thrower : Node2D
var texture

func _ready() -> void:
	$Sprite2D.texture = load(texture)
	var direction = (global_position - get_global_mouse_position()).normalized()
	var impulse = direction * -2000 * throw_strength
	self.apply_impulse(impulse, Vector2.ZERO)
	self.angular_velocity = randf_range(2, 10)

func deal_damage() -> int:
	if is_damage_dealt : return -1
	var weapon_damage : int = randi_range(min_weapon_damage, max_weapon_damage) + base_player_damage
	var damage = int(weapon_damage * throw_strength)
	return damage

func destroy():
	var particles_instance = particles.instantiate()
	particles_instance.global_position = self.global_position
	particles_world_node.add_child(particles_instance)
	$DestroyTimer.stop()
	self.queue_free()

func set_item(_min_weapon_damage, _max_weapon_damage, _base_thrower_damage, _thrower, _texture, _scale : Vector2 = Vector2(1.0, 1.0)):
	min_weapon_damage = _min_weapon_damage
	max_weapon_damage = _max_weapon_damage
	base_player_damage = _base_thrower_damage
	thrower = _thrower
	texture = _texture
	$Sprite2D.scale = _scale

func _on_deactivate_timer_timeout() -> void:
	self.contact_monitor = false

func _on_destroy_timer_timeout() -> void:
	self.queue_free()

func disable():
	is_damage_dealt = true
