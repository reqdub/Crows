extends Node

class_name NPC_Loot

var parent_npc
var npc_inventory : NPC_Inventory

func setup_component(_parent_npc, _npc_inventory):
	parent_npc = _parent_npc
	npc_inventory = _npc_inventory

func drop_loot():
	return

func drop_money():
	pass
