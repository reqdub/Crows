extends VBoxContainer

func set_item(_item_name : String, _item_amount : int, _price : int):
	if _item_name == "":
		$WeaponUnder/WeaponIcon.texture = null
		$ColorRect2/Price.set_text("")
		$ColorRect/Amount.set_text("")
	else:
		$WeaponUnder/WeaponIcon.texture = load("res://Sprites/UI/Weapon_Icons/" + _item_name + ".png")
		$ColorRect2/Price.set_text(str(_price))
		$ColorRect/Amount.set_text(str(_item_amount))
		$ColorRect2/TextureRect.visible = true

func clear_item():
	$WeaponUnder/WeaponIcon.texture = null
	$ColorRect2/Price.set_text("")
	$ColorRect/Amount.set_text("")
