enum type {
	ROCK,
	SPEAR,
	AXE,
	BLUNT,
	SWORD,
	KNIFE,
	SHURIKEN,
	STICK
}

@export var weapon_type : type
@export var min_weapon_damage : int
@export var max_weapon_damage : int
@export var sprite_path : String

func get_weapon_name() -> String:
	return str(type.keys()[weapon_type]).to_lower()

func get_scale() -> Vector2:
	match weapon_type:
		type.ROCK:
			return Vector2(2.0, 2.0)
		type.SPEAR:
			return Vector2(4.0, 4.0)
		type.KNIFE:
			return Vector2(4.0, 4.0)
		type.STICK:
			return Vector2(4.0, 4.0)
		_: return Vector2(1.0, 1.0)
