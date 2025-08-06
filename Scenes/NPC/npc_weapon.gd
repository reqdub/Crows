extends Node2D

@onready var drop_area = get_node("/root/World/Background/Drops")

var is_weapon_dropped : bool = false

func _ready() -> void:
	%Ammunition.add_ammunition(self)

func drop():
	if not is_weapon_dropped:
		drop_weapon()

func drop_weapon():
	is_weapon_dropped = true
	var weapon = load("res://Scenes/Items/Weapon.tscn").instantiate()
	weapon.global_position = self.global_position
	self.queue_free()
	drop_area.call_deferred('add_child', weapon)
