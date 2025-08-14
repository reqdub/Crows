extends Node

class_name inventory

var player_inventory = {
	"coin" : 0,
	"Collectable" : {},
	"Non-Collectable" : {},
	"Weapons" : {
		"rock" : {
			"amount" : 99999,
		}
	}
}

func add_item(item_name, item_amount):
	if player_inventory.has(item_name):
		player_inventory[item_name] += item_amount
	else:
		player_inventory[item_name] = item_amount

func remove_item(item_name, item_amount):
	if player_inventory.has(item_name):
		if player_inventory[item_name] > item_amount:
			player_inventory[item_name] -= item_amount
		else:
			player_inventory[item_name] = 0

func add_money(amount):
	player_inventory["coin"] += amount

func remove_money(amount):
	player_inventory -= amount

func get_money_count() -> int:
	return player_inventory["coin"]
