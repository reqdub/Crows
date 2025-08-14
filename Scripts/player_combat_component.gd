extends Node2D

class_name Player_Combat

@onready var audioplayer = $"../AudioStreamPlayer"
@onready var hit_sound = load("res://Sounds/SFX/hit.wav")
@onready var stun_sound = load("res://Sounds/SFX/stun.ogg")
@onready var battle_text_prefab = preload("res://Scenes/battle_text_indicator.tscn")
@onready var OnScreenText = get_node("/root/World/OnScreenText")

var head_armour : int = 0
var body_armour : int = 0
var arms_armour : int = 0

var block_chance : int = 0
var dodge_chance : int = 75

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
@export var current_weapon : Resource
var current_weapon_type : weapon_type = weapon_type.ROCK
var weapon_damage : Dictionary = {
	weapon_type.ROCK : [1, 4]
}

var can_attack : bool = true
var base_damage : int = 2
var damage : int = 0
var is_in_fight : bool = false

func _ready() -> void:
	%Weapon.texture = load(current_weapon.sprite_path)

func setup_component(_parent, _health_component, _visual_component, _statemachine):
	parent = _parent
	health_component = _health_component
	visual_component = _visual_component
	statemachine = _statemachine

func change_weapon(_weapon):
	var weapon = load("res://Resources/Weapons/" + _weapon + ".tres")
	current_weapon = weapon
	%Weapon.texture = load(current_weapon.sprite_path)

func start_combat(with_target):
	if visual_component.is_praying:
		visual_component.stop_praying()
	Logger.log("Player начинает бой c", with_target.npc_name)
	is_in_fight = true
	statemachine.change_state(statemachine.state.FIGHT)

func end_combat(win : bool, winner = null):
	if not win:
		if winner != null:
			if winner.is_in_group("Guard"):
				parent.is_criminal_scum = false
				parent.criminal.emit(false)
				parent.drop_loot(winner)
			elif winner.is_in_group("Bandit"):
				parent.drop_loot(winner)
	Logger.log("Player ", "заканчивает бой")
	is_in_fight = false
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

func take_hit(_source, amount, _is_headshot):
	if dice_roll() <= block_chance:
		var battle_text_instance : battle_text_indicator = battle_text_prefab.instantiate()
		battle_text_instance.global_position = %IndicatorPosition.global_position
		battle_text_instance.setup("Блок", Color.YELLOW)
		OnScreenText.call_deferred("add_child", battle_text_instance)
	elif dice_roll() <= dodge_chance:
		var battle_text_instance : battle_text_indicator = battle_text_prefab.instantiate()
		battle_text_instance.global_position = %IndicatorPosition.global_position
		battle_text_instance.setup("Уклонение", Color.GREEN)
		OnScreenText.call_deferred("add_child", battle_text_instance)
	else: 
		if _is_headshot:
			var absorbed_damage_amount = amount - head_armour
			if absorbed_damage_amount < 0: absorbed_damage_amount = 0
			health_component.take_damage(absorbed_damage_amount)
		else:
			var absorbed_damage_amount = amount - (body_armour + arms_armour)
			if absorbed_damage_amount < 0: absorbed_damage_amount = 0
			health_component.take_damage(absorbed_damage_amount)

func deal_damage(target):
	if not can_attack: return
	audioplayer.stream = hit_sound
	audioplayer.pitch_scale = randf_range(0.9, 1.1)
	audioplayer.play()
	var random_damage : Array = calculate_damage()
	var damage_to_deal = randi_range(random_damage[0], random_damage[1])
	var is_headshot : bool = false
	if randi_range(0, 100) < 20:
		is_headshot = true
	target.combat_component.take_hit(target, damage_to_deal, is_headshot)
	can_attack = false
	var attack_cooldown : float = randf_range(0.8, 1.4)
	$AttackCooldown.start(attack_cooldown)

func _on_attack_cooldown_timeout() -> void:
	can_attack = true

func dice_roll() -> int:
	return randi_range(0, 100)
