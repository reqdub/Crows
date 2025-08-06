extends Node

class_name NPC_Ammunition

var ammunition : Array = []
var is_hands_empty : bool = true

func add_ammunition(item):
	is_hands_empty = false
	ammunition.append(item)

func drop_ammunition(all = true, _item = null):
	if all:
		for item in ammunition:
			ammunition.erase(item)
			if item != null:
				item.drop()
	else:
		ammunition.erase(_item)
		_item.drop()
	if ammunition.is_empty(): is_hands_empty = true
