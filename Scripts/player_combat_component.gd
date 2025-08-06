extends Node2D

class_name Player_Combat

@onready var audioplayer = $"../AudioStreamPlayer"
@onready var hit_sound = load("res://Sounds/SFX/hit.wav")
@onready var stun_sound = load("res://Sounds/SFX/stun.ogg")

var parent
var health_component : Player_Health
var visual_component
var statemachine

enum weapon_type {
	ROCK,
	SPEAR,
	AXE,
	BLUNT,
	SWORD,
	KNIFE,
	SHURIKEN
}
var current_weapon_type : weapon_type = weapon_type.ROCK
var weapon_damage : Dictionary = {
	weapon_type.ROCK : [1, 4]
}

var can_attack : bool = true
var base_damage : int = 2
var damage : int = 0
var is_in_battle : bool = false

func setup_component(_parent, _health_component, _visual_component, _statemachine):
	parent = _parent
	health_component = _health_component
	visual_component = _visual_component
	statemachine = _statemachine

func start_combat():
	if visual_component.is_praying:
		visual_component.stop_praying()
	Logger.log("Player ", "начинает бой")
	is_in_battle = true
	statemachine.change_state(statemachine.state.FIGHT)

func end_combat(win : bool, winner = null):
	if not win:
		if winner != null and winner.is_in_group("Guard"):
			parent.is_criminal_scum = false
			parent.criminal.emit(false)
			parent.drop_loot(winner)
	Logger.log("Player ", "заканчивает бой")
	is_in_battle = false
	if win: statemachine.change_state(statemachine.state.IDLE)
	else:
		audioplayer.stream = hit_sound
		audioplayer.play()
		statemachine.change_state(statemachine.state.KNOCKDOWN)
	if not parent.is_player_in_initial_position:
		parent.block_player_control.emit(true)
		await parent.walk_to(parent.initial_position)
		parent.block_player_control.emit(false)

func calculate_damage() -> Array:
	var current_weapon_damage : Array = weapon_damage[current_weapon_type]
	var min_weapon_damage = current_weapon_damage[0] + base_damage
	var max_weapon_damage = current_weapon_damage[1] + base_damage
	return [min_weapon_damage, max_weapon_damage]

func take_hit(source, amount, _is_headshot):
	health_component.take_damage(amount)

func deal_damage(target):
	if not can_attack: return
	audioplayer.stream = hit_sound
	audioplayer.pitch_scale = randf_range(0.9, 1.1)
	audioplayer.play()
	var random_damage : Array = calculate_damage()
	var damage = randi_range(random_damage[0], random_damage[1])
	var is_headshot : bool = false
	if randi_range(0, 100) < 20:
		is_headshot = true
	target.combat_component.take_hit(target, damage, is_headshot)
	can_attack = false
	var attack_cooldown : float = randf_range(0.8, 1.4)
	$AttackCooldown.start(attack_cooldown)

func _on_attack_cooldown_timeout() -> void:
	can_attack = true
