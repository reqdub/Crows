# npc_reactions.gd
extends Node
class_name Guard_Reactions

@export var fear_chance : int = 10
@export var caution_chance : int = 75
@export var number_of_warnings : int = 2
@export var number_of_cautions : int = 2

@export var delay_before_start_fight : float = 1.0
@export var npc_reaction_time : float = 0.3

var parent_npc : Guard
var statemachine_node : StateMachine
var health_component : Guard_Health
var movement_component : NPC_Movement
var combat_component : Guard_Combat
var vision_component : Guard_Vision
var visual_component : Guard_Visuals

var potential_enemy: Node2D = null
var stealth_detection_multiplier : float = 1.0
var is_damaged_npc_been_seen : bool = false

signal player_detected(player_node: Node2D)
signal weapon_detected(weapon_node: Node2D)
signal damaged_character_detected(character_node: Node2D)
signal state_change_requested(new_state)

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

func _react_to_weapon(_weapon_node: Node2D) -> void:
	if chech_is_feared():
		health_component.damage_source_list.append(_weapon_node.thrower)
		request_state_change(statemachine_node.state.PANIC)
		parent_npc.say("panic")
	elif health_component.is_damaged:
		parent_npc.say("swearing")
		return
	elif combat_component.is_enemy_in_sight and not health_component.is_damaged:
		number_of_warnings -= 1
		if number_of_warnings <= 0:
			parent_npc.say("criminal_scum")
			await get_tree().create_timer(delay_before_start_fight).timeout
			if check_terminal_statuses(): return
			Logger.log(parent_npc.npc_name, "Игрок рядом бросил камень, хватит предупреждать, бой!")
			combat_component.initiate_combat(potential_enemy)
		else:
			parent_npc.say("criminal_scum")
			Logger.log(parent_npc.npc_name, "Игрок рядом бросил камень, я не ранен, предупреждаю!")
			request_state_change(statemachine_node.state.WARNING)
	elif combat_component.is_enemy_in_sight and health_component.is_damaged:
		Logger.log(parent_npc.npc_name, "Игрок рядом бросил камень, я был ранен, начинаю бой")
		await get_tree().create_timer(npc_reaction_time).timeout
		if check_terminal_statuses(): return
		combat_component.initiate_combat(potential_enemy)
	else:
		if dice_roll() <= caution_chance: 
			await get_tree().create_timer(npc_reaction_time).timeout
			if check_terminal_statuses(): return
			Logger.log(parent_npc.npc_name, "Игрок рядом бросил камень, но проверять я не буду, лучше быстрее уйду")
			movement_component.walk_speed *= 1.5
			parent_npc.say("what")
			number_of_cautions -= 1
			request_state_change(statemachine_node.state.CAUTION)
		else:
			parent_npc.is_angry = true
			Logger.log(parent_npc.npc_name, "Игрок рядом бросил камень, я был далеко, но всё равно зол и иду проверять")
			parent_npc.say("swearing")
			number_of_cautions -= 1
			movement_component.movement_target = parent_npc.danger_point.global_position
			request_state_change(statemachine_node.state.CHASE)

func _react_to_bandit(bandit : Bandit):
	if bandit.stealth_component.check_stealth(): return
	movement_component.stop_moving()
	combat_component.target_enemy = bandit
	combat_component.initiate_combat(bandit)

func _react_to_damaged_character(_char_node: Node2D) -> void:
	if combat_component.is_enemy_in_sight:
		stealth_detection_multiplier = 3.0
		Logger.log(parent_npc.npc_name, str(_char_node) + " ранен, нападаю на обидчика")
		parent_npc.say("criminal_scum")
		await get_tree().create_timer(delay_before_start_fight).timeout
		if _char_node.combat_component.is_in_fight: return
		combat_component.initiate_combat(potential_enemy)
	else:
		is_damaged_npc_been_seen = true
		movement_component.stop_moving()
		Logger.log(parent_npc.npc_name, str(_char_node) + " ранен, преследую обидчика")
		parent_npc.say("who_made_this")
		movement_component.movement_target = parent_npc.danger_point.global_position
		request_state_change(statemachine_node.state.CHASE)

func _react_to_player(player_node: Node2D) -> void:
	player_node.look_at_target(parent_npc)
	potential_enemy = player_node
	Logger.log(parent_npc.npc_name, "Реагирую на игрока")
	if player_node.check_stealth(stealth_detection_multiplier):
		Logger.log(parent_npc.npc_name, "Игрок спрятался")
		potential_enemy = null
		movement_component.stop_moving()
		if combat_component.is_enemy_been_seeing:
			parent_npc.say("where_are_you")
			await get_tree().create_timer(1.0).timeout
		else:
			if randi_range(0, 100) < 33:
				parent_npc.say("it_seemed")
				await get_tree().create_timer(1.0).timeout
		if check_terminal_statuses(): return
		check_if_walking_or_chasing()
	elif player_node.is_criminal_scum: #Если игрок преступник
			movement_component.stop_moving()
			stealth_detection_multiplier = 3.0
			parent_npc.say("criminal_scum")
			Logger.log(parent_npc.npc_name, "Игрок преступник, начинаю бой")
			await get_tree().create_timer(delay_before_start_fight).timeout
			if check_terminal_statuses(): return
			if combat_component.is_in_fight: return
			if player_node.combat_component.is_in_fight:
				parent_npc.say("taunt")
				Logger.log(parent_npc.npc_name, "Игрок уже в бою, дразню его и ухожу")
				movement_component.movement_target = Vector2.ZERO
				request_state_change(statemachine_node.state.WALK)
			else:
				combat_component.initiate_combat(player_node)
	elif player_node.combat_component.is_in_fight: #Если игрок в бою
		combat_component.is_enemy_been_seeing = true
		stealth_detection_multiplier = 2.0
		Logger.log(player_node.npc_name, "Игрок в бою")
		parent_npc.say("taunt")
		check_if_walking_or_chasing()
	elif player_node.health_component.is_knockdown: #Если игрок в нокауте
		combat_component.is_enemy_been_seeing = true
		stealth_detection_multiplier = 2.0
		Logger.log(parent_npc.npc_name, "Игрок без сознания")
		parent_npc.say("taunt")
		check_if_walking_or_chasing()
	elif player_node.visual_component.is_praying and not health_component.is_damaged: #Если молится и я не ранен
		combat_component.is_enemy_been_seeing = true
		stealth_detection_multiplier = 2.0
		Logger.log(parent_npc.npc_name, "Игрок молится")
		movement_component.stop_moving()
		if dice_roll() < 50:
			parent_npc.say("pray")
		await get_tree().create_timer(1.0).timeout
		check_if_walking_or_chasing()
	else: # Игрок ничего не делает
		combat_component.is_enemy_been_seeing = true
		if health_component.is_damaged and health_component.is_in_damager_list(player_node):
			movement_component.stop_moving()
			stealth_detection_multiplier = 3.0
			Logger.log(parent_npc.npc_name, "Я ранен игроком, угрожаю и вступаю в бой")
			parent_npc.say("criminal_scum")
			await get_tree().create_timer(delay_before_start_fight).timeout
			combat_component.initiate_combat(player_node)
		else:
			stealth_detection_multiplier = 2.5
			if is_damaged_npc_been_seen:
				if Karma.get_current_karma() < -30:
					Logger.log(parent_npc.npc_name, "Игрок совершал преступления, бой!")
					parent_npc.say("criminal_scum")
					await get_tree().create_timer(delay_before_start_fight).timeout
					combat_component.initiate_combat(player_node)
				else:
					parent_npc.say("warning")
					Logger.log(parent_npc.npc_name, "У игрока недостаточно низкая карма, но предупреждаю его!")
					request_state_change(statemachine_node.state.WARNING)
					
			elif parent_npc.is_angry:
				Logger.log(parent_npc.npc_name, "Я зол, предупреждаю игрока")
				number_of_warnings -= 1
				if number_of_warnings <= 0:
					Logger.log(parent_npc.npc_name, "Последнее предупреждение исчерпано, вступаю в бой")
					await get_tree().create_timer(delay_before_start_fight).timeout
					combat_component.initiate_combat(player_node)
				else:
					Logger.log(parent_npc.npc_name, "Предупреждаю игрока!")
					parent_npc.say("warning")
					request_state_change(statemachine_node.state.WARNING)
			else:
				Logger.log(parent_npc.npc_name, "Обнаружил игрока")
				request_state_change(statemachine_node.state.CAUTION)
				parent_npc.say("good_day")

func _react_to_zero_damage():
	if check_terminal_statuses(): return
	if statemachine_node.check_is_current_state(statemachine_node.state.CHASE): return
	parent_npc.say("what")
	request_state_change(statemachine_node.state.CHASE)

func _on_health_damaged_by_hit(_source_node: Node2D, _is_headshot: bool) -> void:
	if health_component.is_dead or health_component.is_knockdown or parent_npc.is_panic: return
	if combat_component.is_in_fight: return
	if combat_component.is_enemy_in_sight:
		combat_component.initiate_combat(potential_enemy)
	else:
		parent_npc.is_angry = true
		Logger.log(parent_npc.npc_name, "Игрок рядом бросил камень, я был далеко, но всё равно зол и иду проверять")
		parent_npc.say("criminal_scum")
		number_of_cautions -= 1
		movement_component.movement_target = parent_npc.danger_point.global_position
		request_state_change(statemachine_node.state.CHASE)

func _react_to_knock_out_exit(is_knoked_out : bool):
	if not is_knoked_out:
		parent_npc.say("guard_panic")
		request_state_change(statemachine_node.state.PANIC)

func chech_is_feared(fear_modifier = 1) -> bool:
	if dice_roll() <= (fear_chance * fear_modifier):
		Logger.log(parent_npc.npc_name, "Испуган")
		potential_enemy = null
		movement_component.movement_target = Vector2.ZERO
		return true
	Logger.log(parent_npc.npc_name, "Прошёл проверку на испуг")
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

func check_if_walking_or_chasing():
	if statemachine_node.check_is_current_state(statemachine_node.state.WALK) \
	or statemachine_node.check_is_current_state(statemachine_node.state.CHASE):
		movement_component.movement_target = Vector2.ZERO
		movement_component.move_to_point()
