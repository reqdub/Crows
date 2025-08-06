extends Node
class_name StateMachine

enum state {
	IDLE,
	WALK,
	PANIC,
	CHASE,
	BATTLE,
	KNOCKDOWN,
	CAUTION,
	WARNING,
	SPAWNED
}

@onready var states = {
	state.IDLE: $Idle,
	state.WALK: $Walk,
	state.PANIC: $Panic,
	state.CHASE: $Chase,
	state.BATTLE: $Battle,
	state.KNOCKDOWN: $Knockdown,
	state.CAUTION: $Caution,
	state.WARNING: $Warning
}

var parent
var actions_node: Actions
var health_component
var combat_component
var movement_component : NPC_Movement

var current_state := state.SPAWNED
var previous_state := state.IDLE

func setup_component(_parent, _actions, _health_component, _combat_component, _movement_component):
	parent = _parent
	actions_node = _actions
	health_component = _health_component
	combat_component = _combat_component
	movement_component = _movement_component
	for key in states:
		var state_node = states[key]
		state_node.statemachine_node = self
		state_node.character = parent
		state_node.movement_node = movement_component
		state_node.actions_node = actions_node
	parent.reactions_component.connect("state_change_requested", change_state)

func change_state(new_state: state) -> void:
	if health_component.is_knockdown and current_state != state.KNOCKDOWN:
		if new_state == current_state:
			Logger.log(parent.npc_name, " Игнорирую переход: %s" % state.keys()[new_state])
			return

	Logger.log(parent.npc_name, " Перехожу из %s в %s" % [
		state.keys()[current_state],
		state.keys()[new_state]
	])

	_exit_state(current_state)
	previous_state = current_state
	current_state = new_state
	_enter_state(current_state)
	Logger.log(parent.npc_name, " Перешел в состояние %s" % state.keys()[new_state])

func _exit_state(state_to_exit: state) -> void:
	match state_to_exit:
		state.WALK, state.CHASE:
			movement_component.stop_moving()
		state.WARNING:
			states[state.WARNING].stop_warnings()
			Logger.log(parent.npc_name, " выходя из WARRNING останавливаю предупреждения CAUTIONS")
			if current_state == state.CAUTION:
				states[state.CAUTION].stop_cautions()
		state.CAUTION:
			states[state.CAUTION].stop_cautions()
			Logger.log(parent.npc_name, " выходя из CAUTION останавливаю предупреждения WARRNINGS")
			if current_state == state.WARNING:
				states[state.WARNING].stop_warnings()
		_:
			pass

func _enter_state(state_to_enter: state) -> void:
	match state_to_enter:
		state.IDLE:
			states[state.IDLE].idle()
		state.WALK:
			states[state.WALK].walk()
		state.PANIC:
			states[state.PANIC].panic()
		state.CHASE:
			states[state.CHASE].chase()
		state.BATTLE:
			states[state.BATTLE].battle()
		state.KNOCKDOWN:
			states[state.KNOCKDOWN].knockdown()
		state.CAUTION:
			states[state.CAUTION].caution()
		state.WARNING:
			if not combat_component.is_in_fight:
				states[state.WARNING].warning()
		state.SPAWNED:
			pass

func _stop_alert_states() -> void:
	Logger.log(parent.npc_name, " остановка всех предупреждений")
	states[state.WARNING].stop_warnings()
	states[state.CAUTION].stop_cautions()

func check_is_current_state(check_state) -> bool:
	if current_state == check_state: return true
	return false
