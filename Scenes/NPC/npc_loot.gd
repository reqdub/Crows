extends Node

class_name NPC_Loot

@onready var collectable = preload("res://Scenes/Droppable/collectable_item.tscn")
@onready var weapon = preload("res://Scenes/Droppable/droppable_weapon.tscn")
@onready var drop_area = get_node("/root/World/Background/Drops")

@export var loot : loot_data
var npc_loot

var parent_npc
var is_loot_dropped : bool = false

func _ready() -> void:
	npc_loot = loot.data

func setup_component(_parent_npc):
	parent_npc = _parent_npc

func drop_loot(collector):
	if is_loot_dropped: return
	var npc_inventory_dict = npc_loot
	for category in npc_inventory_dict.keys():
		if category.is_empty(): return
		if category == "coin":
			if randi_range(0, 100) <= npc_inventory_dict["coin"]["chance"]:
				var item_name = "coin"
				var item_amount = randi_range(0, npc_inventory_dict["coin"]["amount"])
				for i in range(item_amount):
					var droppable_instance = collectable.instantiate()
					droppable_instance.global_position = %LootDropPosition.global_position
					droppable_instance.set_item(item_name, 1, collector)
					drop_area.call_deferred("add_child", droppable_instance)
		else:
			for item in npc_inventory_dict[category]:
				if npc_inventory_dict[category].is_empty(): continue
				var item_name = npc_inventory_dict[category][item]["name"]
				var item_amount = randi_range(0, npc_inventory_dict[category][item]["amount"])
				var item_chance = npc_inventory_dict[category][item]["chance"]
				if randi_range(0, 100) <= item_chance:
					for i in range(item_amount):
						var droppable_instance
						match  category:
							"Collectable" : droppable_instance = collectable.instantiate()
							"Weapons" : droppable_instance = weapon.instantiate()
						droppable_instance.global_position = %LootDropPosition.global_position
						droppable_instance.set_item(item_name, 1, collector)
						drop_area.call_deferred("add_child", droppable_instance)
	is_loot_dropped = true
