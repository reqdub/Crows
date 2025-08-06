extends Node2D

class_name Guard_Vision

@onready var npc_view = %ViewArea
var parent_npc
var health_component : Guard_Health
var combat_component : Guard_Combat
var reaction_component : Guard_Reactions

func setup_component(_parent_npc, _health_component, _combat_component, _reaction_component):
	parent_npc = _parent_npc
	health_component = _health_component
	combat_component = _combat_component
	reaction_component = _reaction_component
	
	combat_component.connect("combat_started", _on_npc_combat_started)
	combat_component.connect("combat_ended", _on_npc_combat_ended)


func _on_view_area_body_entered(body: Node2D) -> void:
	# First, check for terminal statuses from the health component
	if health_component.is_dead or health_component.is_knockdown: return
	# Also check other terminal statuses the main NPC might have
	if parent_npc.is_panic or combat_component.is_in_fight: return # Keep these checks for now

	if body.is_in_group("Throwable"):
		Logger.log(parent_npc.name, "Реагирую на камень")
		reaction_component._react_to_weapon(body)
	elif body.is_in_group("Player"):
		Logger.log(parent_npc.name, "Заметил игрока!")
		combat_component.is_enemy_in_sight = true
		combat_component.potential_enemy = body
		reaction_component._react_to_player(body)
	elif body.is_in_group("Character"): # Assuming 'character' is a main NPC script/node with an 'is_damaged' property
		# You need to ensure 'body.character' correctly points to the NPC script itself
		if body.has_method("get_health_component") and body.get_health_component().is_damaged:
			reaction_component._react_to_damaged_character(body)
			Logger.log(parent_npc.name, "Реагирую на раненого персонажа")

func _on_view_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		combat_component.is_enemy_in_sight = false
		reaction_component._react_to_player_exit(body) # Handle what happens when player leaves sight

func set_vision(can_see : bool):
	if can_see:
		%ViewArea.set_deferred("monitorable", true)
		%ViewArea.set_deferred("monitoring", true)
	else:
		%ViewArea.set_deferred("monitorable", false)
		%ViewArea.set_deferred("monitoring", false)

func _on_npc_combat_started(_with : Node2D):
	set_vision(false)

func _on_npc_combat_ended(_winner : bool):
	set_vision(true)
