extends GridContainer

var slots : Array = []

var selected_slot
var items_in_slots = {}

var trade_target : player

var weapons = {
	"stick" : {
		"chance" : 50,
		"price" : 2,
		"amount" : randi_range(1, 15)
	},
	"knife" : {
		"chance" : 35,
		"price" : 8,
		"amount" : randi_range(1, 10)
	},
	"spear" : {
		"chance" : 15,
		"price" : 20,
		"amount" : randi_range(1, 10)
	}
}

func _ready():
	var button_index = 0
	for button_node in get_children():
		slots.append(button_node)
		var button = button_node.get_node("WeaponUnder/WeaponIcon/Button")
		button.pressed.connect(_on_trade_slot_pressed.bind(button_index))
		button_index += 1
	populate_inventory()

func populate_inventory():
	var weapon_list = weapons.keys()
	for i in slots.size():
		if not weapon_list.is_empty():
			var random_weapon = weapon_list[randi_range(0, weapon_list.size() - 1)]
			var weapon_spawn_chance = weapons[random_weapon]["chance"]
			var weapon_amount = weapons[random_weapon]["amount"]
			var weapon_price = weapons[random_weapon]["price"]
			if randi_range(0, 100) < weapon_spawn_chance:
				slots[i].set_item(random_weapon, weapon_amount, weapon_price)
				weapon_list.erase(random_weapon)
				items_in_slots[slots[i]] = weapons[random_weapon]
				items_in_slots[slots[i]]["name"] = random_weapon
			else:
				slots[i].set_item("", 0, 0)

func _on_trade_slot_pressed(slot_index):
	selected_slot = slots[slot_index]
	if not items_in_slots.has(selected_slot): 
		%TradeWindow.visible = false
		return
	var item_name = items_in_slots[selected_slot]["name"]
	var item_amount = items_in_slots[selected_slot]["amount"]
	var item_price = items_in_slots[selected_slot]["price"]
	selected_slot.set_item(item_name, item_amount, item_price)
	%TradeWindow.set_item(item_name, item_amount, item_price)
	%TradeWindow.visible = true

func _on_accept_button_pressed() -> void:
	var price = items_in_slots[selected_slot]["amount"] * items_in_slots[selected_slot]["price"]
	if Inventory.player_inventory["coin"] >= price:
		AudioManager.play_sound(SoundCache.gold_drop_sound)
		trade_target.change_money(-price)
		trade_target.add_equipment("Weapons", items_in_slots[selected_slot]["name"], items_in_slots[selected_slot]["amount"])
		selected_slot.clear_item()
		items_in_slots.erase(selected_slot)
		selected_slot = null
		%TradeWindow.visible = false
	else:
		$"../TradeWindow/Text/Label".set_text("Недостаточно денег!")

func _on_decline_button_pressed() -> void:
	%TradeWindow.visible = false

func _on_texture_button_pressed() -> void:
	%Movement.movement_target = Vector2.ZERO
	%StateMachine.change_state(%StateMachine.state.WALK)
	$"../CloseButton".visible = false
	%TraderInventory.visible = false
	%TradeWindow.visible = false

func _on_trade_button_pressed() -> void:
	$"../TradeButton".visible = false
	%TraderInventory.visible = true
	$"../CloseButton".visible = true
