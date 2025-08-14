extends VBoxContainer

@onready var normal_texture = load("res://Sprites/UI/Weapon_Icons/Weapon_Cell.png")
@onready var selected_texture = load("res://Sprites/UI/Weapon_Icons/Weapon_Cell_Selected.png")
var selected_cell

var weapons : Array = []
var weapon_names : Array = []
var selected_weapon
signal weapon_changed(weapon)

func _ready() -> void:
	for weapon in Inventory.player_inventory["Weapons"]:
		add_weapon(weapon)
	weapons[0].get_node("WeaponUnder").texture = selected_texture
	selected_cell = weapons[0]

func _on_button_pressed(_weapon_index : int) -> void:
	select_weapon(_weapon_index)
	self.visible = !self.visible

func select_weapon(_weapon_index):
	selected_cell.get_node("WeaponUnder").texture = normal_texture
	selected_cell = weapons[_weapon_index]
	selected_cell.get_node("WeaponUnder").texture = selected_texture
	weapon_changed.emit(weapon_names[_weapon_index])

func _on_weapon_count_changed(_weapon_name):
	var weapon_index = weapon_names.find(_weapon_name)
	weapons[weapon_index].get_node("ColorRect/Label").set_text(str(Inventory.player_inventory["Weapons"][_weapon_name]["amount"]))
	if Inventory.player_inventory["Weapons"][_weapon_name]["amount"] == 0:
		remove_weapon(_weapon_name)

func add_weapon(_weapon_name):
	if weapon_names.has(_weapon_name):
		var weapon_index = weapon_names.find(_weapon_name)
		weapons[weapon_index].get_node("ColorRect/Label").set_text(str(Inventory.player_inventory["Weapons"][_weapon_name]["amount"]))
	else:
		var new_button = load("res://Scenes/weapon_button.tscn").instantiate()
		new_button.get_node("WeaponUnder/WeaponIcon").texture = load("res://Sprites/UI/Weapon_Icons/" + _weapon_name.to_lower() + ".png")
		new_button.get_node("ColorRect/Label").set_text(str(Inventory.player_inventory["Weapons"][_weapon_name]["amount"]))
		add_child(new_button)
		weapons.append(new_button)
		weapon_names.append(_weapon_name)
		var button : Button = new_button.get_node("WeaponUnder/WeaponIcon/Button")
		button.pressed.connect(_on_button_pressed.bind(weapons.find(new_button)))

func remove_weapon(_weapon_name):
	var weapon_index = weapon_names.find(_weapon_name)
	var weapon = weapons[weapon_index]
	weapon_names.erase(_weapon_name)
	weapons.erase(weapons[weapon_index])
	remove_child(weapon)
	select_weapon(0)

func _on_weapon_added(_weapon_name):
	add_weapon(_weapon_name)
