extends Node2D

@onready var animation_player = %AnimationPlayer

var parent
var health_component
var visual_component

enum state {
	IDLE,
	FIGHT,
	STEALTH,
	KNOCKDOWN
}
var current_state = state.IDLE

func setup_component(_parent, _health_component, _visual_component):
	parent = _parent
	health_component = _health_component
	visual_component = _visual_component

func change_state(new_state):
	await exit_state()
	enter_state(new_state)

func enter_state(new_state):
	match new_state:
		0 : #IDLE
			idle_state()
		1 : #FIGHT
			parent.block_player_control.emit(true)
			fight_state()
		2 : #STEALTH
			stealth_state()
		3:#KNOCKDOWN
			parent.block_player_control.emit(true)
			visual_component.apply_head_damage()
			knockdown_state()

func exit_state():
	match current_state:
		0 : #IDLE
			pass
		1 : #FIGHT
			parent.block_player_control.emit(false)
		2 : #STEALTH
			pass
		3:#KNOCKDOWN
			parent.block_player_control.emit(false)
			await get_tree().create_timer(2.0).timeout
			%PrescenceArea.set_deferred("monitorable", true)
			%PrescenceArea.set_deferred("monitoring", true)

func idle_state():
	current_state = state.IDLE
	animation_player.play("Idle")

func fight_state():
	current_state = state.FIGHT

func stealth_state():
	current_state = state.STEALTH
	parent.is_in_stealth = true

func knockdown_state():
	current_state = state.KNOCKDOWN
	Logger.log("Игрок ", " в нокдауне")
	health_component.is_knockdown = true
	animation_player.play("Knockdown")
	await animation_player.animation_finished
	health_component.is_knockdown = false
	change_state(state.IDLE)
