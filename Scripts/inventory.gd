extends Node

class_name inventory

var player_inventory = {
	"coin" : 0,
	"Collectable" : {},
	"Non-Collectable" : {},
	"Weapons" : {
		"rock" : {
			"amount" : 99999,
		},
		"knife" : {
			"amount" : 5
		}
	}
}

func add_item(item_category, item_name, item_amount):
	match item_category:
		"coin" : 
			add_money(item_amount)
		"Collectable" :
			if player_inventory["Collectable"].has(item_name):
				player_inventory["Collectable"][item_name]["amount"] += item_amount
			else:
				player_inventory["Collectable"][item_name] = {"amount" : item_amount}
		"Non-Collectable" :
			if player_inventory["Non-Collectable"].has(item_name):
				player_inventory["Non-Collectable"][item_name]["amount"] += item_amount
			else:
				player_inventory["Non-Collectable"][item_name] = {"amount" : item_amount}
		"Weapons" :
			if player_inventory["Weapons"].has(item_name):
				player_inventory["Weapons"][item_name]["amount"] += item_amount
			else:
				player_inventory["Weapons"][item_name] = {"amount" : item_amount}

func remove_item(item_category, item_name, item_amount):
	match item_category:
		"coin" : 
			remove_money(item_amount)
		"Collectable" :
			if player_inventory["Collectable"].has(item_name):
				player_inventory["Collectable"][item_name]["amount"] -= item_amount
			else:
				player_inventory["Collectable"][item_name] = {"amount" : item_amount}
		"Non-Collectable" :
			if player_inventory["Non-Collectable"].has(item_name):
				player_inventory["Non-Collectable"][item_name]["amount"] -= item_amount
			else:
				player_inventory["Non-Collectable"][item_name] = {"amount" : item_amount}
		"Weapons" :
			if player_inventory["Weapons"].has(item_name):
				player_inventory["Weapons"][item_name]["amount"] -= item_amount
			else:
				player_inventory["Weapons"][item_name] = {"amount" : item_amount}

func add_money(amount):
	player_inventory["coin"] += amount

func remove_money(amount):
	player_inventory["coin"] -= amount

func get_money_count() -> int:
	return player_inventory["coin"]
