extends Node2D

var menus_shown : bool = false

@onready var main_button : Sprite2D = $MenuButton

func _ready() -> void:
	$Buttons/Inventory.visible = false
	$Buttons/Weapons.visible = false
	$Buttons/Menu.visible = false
	menus_shown = false

func _on_menu_list_button_pressed() -> void:
	if not menus_shown:
		show_menus()
	else:
		hide_menus()

func show_menus():
	$AnimationPlayer.play("Show")
	$Buttons/Inventory.visible = true
	$Buttons/Weapons.visible = true
	$Buttons/Menu.visible = true
	menus_shown = true

func hide_menus():
	$AnimationPlayer.play("Hide")
	await $AnimationPlayer.animation_finished
	$Buttons/Inventory.visible = false
	$Buttons/Weapons.visible = false
	$Buttons/Menu.visible = false
	menus_shown = false

func _on_inventory_button_pressed() -> void:
	pass

func _on_weapons_button_pressed() -> void:
	%WeaponScrollBar.visible = !%WeaponScrollBar.visible
	hide_menus()

func _on_menu_button_pressed() -> void:
	%Menu.show_menu()
	hide_menus()
