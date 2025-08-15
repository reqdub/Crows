extends Node2D

@onready var drop_area = get_node("/root/World/Background/Drops")
@onready var weapon = preload("res://Scenes/Droppable/droppable_weapon.tscn")

@export var weapon_name : String

var is_weapon_dropped : bool = false

func _ready() -> void:
	%Ammunition.add_ammunition(self)

func drop(by_who : Node2D):
	if not is_weapon_dropped:
		drop_weapon(by_who)

func drop_weapon(by_who : Node2D):
	is_weapon_dropped = true
	var weapon_to_drop : droppable_weapon = weapon.instantiate()
	weapon_to_drop.set_item(weapon_name, 1, by_who)
	weapon_to_drop.global_position = self.global_position
	weapon_to_drop.rotation = self.rotation
	drop_area.call_deferred('add_child', weapon_to_drop)
	self.queue_free()
