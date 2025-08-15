extends Node

class_name NPC_Ammunition

var ammunition : Array = []
var is_hands_empty : bool = true

func _ready() -> void:
	%Health.connect("knocked_out", _on_knocked_out)

func add_ammunition(item):
	is_hands_empty = false
	ammunition.append(item)

func drop_ammunition(all = true, _item = null, by_who : Node2D = null):
	if all:
		for item in ammunition:
			ammunition.erase(item)
			if item != null:
				item.drop(by_who)
	else:
		ammunition.erase(_item)
		_item.drop(by_who)
	if ammunition.is_empty(): is_hands_empty = true

func _on_knocked_out(is_knocked_out, by_who):
	if is_knocked_out:
		drop_ammunition(true, null, by_who)
