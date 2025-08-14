extends Node2D

class_name Bandit_Vision

@onready var npc_view = %ViewArea
var parent_npc : Bandit
var health_component : Bandit_Health
var combat_component : Bandit_Combat
var reaction_component : Bandit_Reactions

var ignore_reaction_list : Array[Node2D] = []

func setup_component(_parent_npc, _health_component, _combat_component, _reaction_component):
	parent_npc = _parent_npc
	health_component = _health_component
	combat_component = _combat_component
	reaction_component = _reaction_component
	
	combat_component.connect("combat_started", _on_npc_combat_started)
	combat_component.connect("combat_ended", _on_npc_combat_ended)


func _on_view_area_body_entered(body: Node2D) -> void:
	if ignore_reaction_list.has(body):return
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
	elif body.is_in_group("Peasant"):
		reaction_component._react_to_peasant(body)
		Logger.log(parent_npc.name, " реагирую на крестьянина")
	elif body.is_in_group("Guard"):
		Logger.log(parent_npc.npc_name, " реагирую на бандита")
		reaction_component._react_to_guard(body)

func _on_view_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		combat_component.is_enemy_in_sight = false
		reaction_component._react_to_player_exit(body) # Handle what happens when player leaves sight

func set_vision(can_see : bool):
	if can_see:
		await get_tree().create_timer(1.0).timeout
		%ViewArea.set_deferred("monitorable", true)
		%ViewArea.set_deferred("monitoring", true)
	else:
		%ViewArea.set_deferred("monitorable", false)
		%ViewArea.set_deferred("monitoring", false)

func add_to_ignore_list(target):
	if ignore_reaction_list.has(target): return
	ignore_reaction_list.append(target)

func _on_npc_combat_started():
	set_vision(false)

func _on_npc_combat_ended():
	set_vision(true)
