extends Node2D

@onready var drop_area = get_node("/root/World/Background/Drops")
@onready var weapon = preload("res://Scenes/Droppable/droppable_weapon.tscn")

@export var weapon_type : String
@export var weapon_name : String

var is_weapon_dropped : bool = false

func _ready() -> void:
	%Ammunition.add_ammunition(self)

func drop():
	if not is_weapon_dropped:
		drop_weapon()

func drop_weapon():
	is_weapon_dropped = true
	var spear : droppable_weapon = weapon.instantiate()
	spear.set_item(weapon_type, weapon_name, %Health.damage_source_list[-1])
	spear.global_position = self.global_position
	spear.rotation = self.rotation
	drop_area.call_deferred('add_child', spear)
	self.queue_free()
