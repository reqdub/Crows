# npc_reactions.gd
extends Node
class_name NPC_Reactions

# References to other components that this component will interact with
# These should be references to sibling nodes, or fetched from the parent (the main NPC)
var parent_npc : npc
var statemachine_node : StateMachine
var health_component : NPC_Health
var movement_component : NPC_Movement
var combat_component : NPC_Combat
var vision_component : NPC_Vision
var visual_component : NPC_Visuals
# Add reference to a future combat component if you create one, e.g.:
# @onready var combat_component : NPC_Combat = parent_npc.combat_component

# Constants and variables directly related to reaction logic
@export var fear_chance : int = 10 # Default from your script
@export var caution_chance : int = 75 # Average from your script (50-100)
@export var number_of_warnings : int = 2 # Default from your script
@export var number_of_cautions : int = 2 # Default from your script

@export var delay_before_start_fight : float = 0.5
@export var npc_reaction_time : float = 0.3

# State variables that describe the NPC's perception
var potential_enemy: Node2D = null
var stealth_detection_multiplier : float = 1.0 # Stealth detection multiplier

# Signals to communicate decisions back to the main NPC or other components
signal player_detected(player_node: Node2D)
signal weapon_detected(weapon_node: Node2D)
signal damaged_character_detected(character_node: Node2D)
signal state_change_requested(new_state) # Request state change from StateMachine

func setup_component(_parent_npc, _statemachine_node, _health_component, _movement_component, _combat_component, _vision_component, _visual_component):
	parent_npc = _parent_npc
	statemachine_node = _statemachine_node
	health_component = _health_component
	movement_component = _movement_component
	combat_component = _combat_component
	vision_component = _vision_component
	visual_component = _visual_component
	
	health_component.connect("damaged_by_hit", _on_health_damaged_by_hit)
	health_component.connect("knocked_out", _react_to_knock_out_exit)
# --- Individual Reaction Functions ---

func _react_to_weapon(_weapon_node: Node2D) -> void:
	if chech_is_feared(): # This function needs to be in this component
		request_state_change(statemachine_node.state.PANIC)
		parent_npc.say("panic")
	elif health_component.is_damaged: # Check health component's state
		parent_npc.say("swearing")
		return # Do nothing else if damaged
	elif combat_component.is_enemy_in_sight and not health_component.is_damaged:
		number_of_warnings -= 1
		parent_npc.say("warning")
		Logger.log(parent_npc.name, "Игрок рядом бросил камень, я не ранен, но предупреждаю его")
		request_state_change(statemachine_node.state.WARNING)
		if number_of_warnings <= 0:
			await get_tree().create_timer(delay_before_start_fight).timeout
			if check_terminal_statuses(): return
			combat_component.initiate_combat(potential_enemy)
			Logger.log(parent_npc.name, "Игрок рядом бросил камень, хватит предупреждать, бой!")
			combat_component.initiate_combat(potential_enemy)
			request_state_change(statemachine_node.state.BATTLE)
	elif combat_component.is_enemy_in_sight and health_component.is_damaged:
		Logger.log(parent_npc.name, "Игрок рядом бросил камень, я был ранен, начинаю бой")
		await get_tree().create_timer(npc_reaction_time).timeout
		if check_terminal_statuses(): return
		combat_component.initiate_combat(potential_enemy)
		request_state_change(statemachine_node.state.BATTLE)
	else: # Player is far
		if dice_roll() <= caution_chance: 
			await get_tree().create_timer(npc_reaction_time).timeout
			if check_terminal_statuses(): return
			movement_component.movement_target = parent_npc.danger_point.global_position # Still directly referencing NPC's danger_point
			movement_component.point_before_chase = parent_npc.global_position
			Logger.log(parent_npc.name, "Игрок рядом бросил камень, но проверять я не буду, лучше быстрее уйду")
			movement_component.walk_speed /= 1.2 # Adjusting parent's speed directly for now
			parent_npc.say("what")
			number_of_cautions -= 1
			request_state_change(statemachine_node.state.CAUTION)
		else:
			parent_npc.is_angry = true # Still directly referencing NPC's is_angry
			Logger.log(parent_npc.name, "Игрок рядом бросил камень, я был далеко, но всё равно зол и иду проверять")
			parent_npc.say("swearing")
			number_of_cautions -= 1
			movement_component.movement_target = parent_npc.danger_point.global_position
			request_state_change(statemachine_node.state.CHASE)

func _react_to_damaged_character(char_node: Node2D) -> void:
	var damaged_char_script = char_node.character
	if chech_is_feared():
		if check_terminal_statuses(): return
		movement_component.stop_moving()
		parent_npc.say("call_for_help")
		request_state_change(statemachine_node.state.PANIC)
	else:
		if damaged_char_script.is_panic:
			parent_npc.say("joke")

func _react_to_player(player_node: Node2D) -> void:
	player_node.look_at_target(parent_npc) # Player script should have this method
	potential_enemy = player_node
	Logger.log(parent_npc.name, "Реагирую на игрока")

	if player_node.check_stealth(stealth_detection_multiplier): # Player script method
		Logger.log(parent_npc.name, "Игрок спрятался")
		potential_enemy = null
		movement_component.stop_moving()
		if combat_component.is_enemy_been_seeing:
			parent_npc.say("it_seemed")
		else:
			parent_npc.say("where_are_you")
		await get_tree().create_timer(1.0).timeout
		if check_terminal_statuses(): return
		if statemachine_node.check_is_current_state(statemachine_node.state.WALK) \
		or statemachine_node.check_is_current_state(statemachine_node.state.CHASE):
			movement_component.movement_target = Vector2.ZERO
			movement_component.move_to_point() # This call assumes walker handles moving to null target as stopping
	elif player_node.combat_component.is_in_battle: # Player script property
		combat_component.is_enemy_been_seeing = true
		stealth_detection_multiplier = 2.0
		Logger.log(player_node.name, "Игрок в бою")
		parent_npc.say("taunt")
		if statemachine_node.check_is_current_state(statemachine_node.state.WALK) \
		or statemachine_node.check_is_current_state(statemachine_node.state.CHASE):
			movement_component.movement_target = Vector2.ZERO
			movement_component.move_to_point()
	elif player_node.health_component.is_knockdown: # Player script property
		combat_component.is_enemy_been_seeing = true
		stealth_detection_multiplier = 2.0
		Logger.log(parent_npc.name, "Игрок без сознания")
		parent_npc.say("taunt")
		if statemachine_node.check_is_current_state(statemachine_node.state.WALK) \
		or statemachine_node.check_is_current_state(statemachine_node.state.CHASE):
			movement_component.movement_target = Vector2.ZERO
			movement_component.move_to_point()
	elif player_node.visual_component.is_praying and not health_component.is_damaged: # Player script property
		combat_component.is_enemy_been_seeing = true
		stealth_detection_multiplier = 2.0
		Logger.log(parent_npc.name, "Игрок молится")
		movement_component.stop_moving()
		if dice_roll() < 50:
			parent_npc.say("pray")
		await get_tree().create_timer(1.0).timeout
		if statemachine_node.check_is_current_state(statemachine_node.state.WALK) \
		 or statemachine_node.check_is_current_state(statemachine_node.state.CHASE):
			movement_component.movement_target = Vector2.ZERO
			movement_component.move_to_point()
	else: # Player is doing nothing specific
		combat_component.is_enemy_been_seeing = true
		if health_component.is_damaged:
			movement_component.stop_moving()
			stealth_detection_multiplier = 3.0
			Logger.log(parent_npc.name, "Я ранен игроком, угрожаю и вступаю в бой")
			await get_tree().create_timer(delay_before_start_fight).timeout
			if check_terminal_statuses(): return
			if combat_component.is_in_fight: return
			combat_component.initiate_combat(player_node) # Will move to combat component
			parent_npc.say("threat")
			request_state_change(statemachine_node.state.BATTLE)
		else:
			stealth_detection_multiplier = 2.5
			if parent_npc.is_angry:
				Logger.log(parent_npc.name, "Я зол, предупреждаю игрока")
				number_of_warnings -= 1
				if number_of_warnings <= 0:
					Logger.log(parent_npc.name, "Последнее предупреждение исчерпано, вступаю в бой")
					await get_tree().create_timer(delay_before_start_fight).timeout
					if check_terminal_statuses(): return
					if combat_component.is_in_fight: return
					combat_component.initiate_combat(player_node)
					request_state_change(statemachine_node.state.BATTLE)
				else:
					Logger.log(parent_npc.name, "Предупреждаю игрока!")
					parent_npc.say("warning")
					request_state_change(statemachine_node.state.WARNING)
			else:
				Logger.log(parent_npc.name, "Обнаружил игрока")
				request_state_change(statemachine_node.state.CAUTION)
				parent_npc.say("find_you")

func _react_to_player_exit(_player_node: Node2D) -> void:
	combat_component.is_enemy_in_sight = false

func _react_to_zero_damage():
	if check_terminal_statuses(): return
	if statemachine_node.check_is_current_state(statemachine_node.state.CHASE): return
	parent_npc.say("what")
	request_state_change(statemachine_node.state.CHASE)

func _on_health_damaged_by_hit(_source_node: Node2D, _is_headshot: bool) -> void:
	if health_component.is_dead or health_component.is_knockdown or parent_npc.is_panic: return
	if combat_component.is_in_fight: return # Already in combat, just keep fighting
	if combat_component.is_enemy_in_sight:
		combat_component.initiate_combat(potential_enemy)
		request_state_change(statemachine_node.state.BATTLE)
	else:
		parent_npc.is_angry = true # Still directly referencing NPC's is_angry
		Logger.log(parent_npc.name, "Игрок рядом бросил камень, я был далеко, но всё равно зол и иду проверять")
		parent_npc.say("swearing")
		number_of_cautions -= 0
		movement_component.movement_target = parent_npc.danger_point.global_position
		request_state_change(statemachine_node.state.CHASE)
# --- Helper functions (moved from main NPC or new ones) ---

func _react_to_knock_out_exit(is_knoked_out : bool):
	if not is_knoked_out:
		parent_npc.say("call_for_help")
		request_state_change(statemachine_node.state.PANIC)

func chech_is_feared(fear_modifier = 1) -> bool:
	if dice_roll() <= (fear_chance * fear_modifier):
		Logger.log(parent_npc.name, "Испуган")
		potential_enemy = null # Clearing potential enemy makes sense here
		movement_component.movement_target = Vector2.ZERO # Direct reference for now
		return true
	Logger.log(parent_npc.name, "Прошёл проверку на испуг")
	return false

func dice_roll() -> int:
	return randi_range(0, 100)

func request_state_change(new_state) -> void:
	state_change_requested.emit(new_state)

func check_terminal_statuses() -> bool:
	if health_component.is_dead: return true
	if health_component.is_knockdown: return true
	if parent_npc.is_panic: return true
	return false
