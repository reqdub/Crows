# npc_combat.gd
extends Node
class_name NPC_Combat

# References to scene nodes needed for combat (e.g., Brawl node, weapon spawns)
@onready var brawl_node : Brawl = get_node("/root/World/Brawl") # Global node
@onready var drop_position = %LootDropPosition # To drop loot on death/knockout
@onready var audio_stream_player = %AudioStreamPlayer2D
@onready var hit_sound = load("res://Sounds/SFX/hit.wav")

var parent_npc
var vision_component : NPC_Vision
var statemachine_node : StateMachine
var health_component : NPC_Health
var reactions_component
var movement_component : NPC_Movement

@export var delay_before_start_fight : float = 0.5
@export var attack_damage : int = randi_range(2, 8)
var can_attack : bool = true

var target_enemy : Node2D = null
var is_in_fight : bool = false
var is_enemy_in_sight : bool = false
var potential_enemy : Node2D = null
var is_enemy_been_seeing: bool = false
var last_attack_time : float = 0.0

# Signals for other components/systems to react to combat events
signal combat_started()
signal combat_ended()
signal attacked_target(target: Node2D, damage_dealt: int)

func setup_component(_parent_npc, _statemachine_node, _movement_component, _health_component, _reactions_component, _vision_component):
	parent_npc = _parent_npc
	statemachine_node = _statemachine_node
	movement_component = _movement_component
	health_component = _health_component
	reactions_component = _reactions_component
	vision_component = _vision_component
	
	health_component.knocked_out.connect(_on_health_knocked_out)
# Helper for reaction component to request state change, now goes through combat

func initiate_combat(target: Node2D) -> void:
	if is_in_fight or health_component.is_dead or health_component.is_knockdown: return
	target_enemy = target
	Logger.log(parent_npc.npc_name, str("Начинаю бой с ", target_enemy.npc_name))
	combat_started.emit()
	statemachine_node.change_state(statemachine_node.state.BATTLE)

func start_combat(with_target):
	is_in_fight = true
	if not statemachine_node.check_is_current_state(statemachine_node.state.BATTLE):
		movement_component.stop_moving()
		statemachine_node.change_state(statemachine_node.state.BATTLE)
	parent_npc.dialogue_component.visible = false
	health_component.health_bar.visible = false

func end_combat(win: bool, _winner) -> void:
	if not is_in_fight: return
	is_in_fight = false
	if reactions_component.check_terminal_statuses(): return
	target_enemy = null
	Logger.log(parent_npc.npc_name, str("Бой завершился, я победил? ", win))
	if win:
		combat_ended.emit()
		parent_npc.is_angry = false
		parent_npc.say("taunt")
		await get_tree().create_timer(1.0).timeout
		statemachine_node.change_state(statemachine_node.state.WALK)
	else:
		combat_ended.emit()
		statemachine_node.change_state(statemachine_node.state.WALK)
	

func start_brawl():
	if is_in_fight: return
	await brawl_node.start_brawl(parent_npc, target_enemy)

func take_hit(source, amount, is_headshot : bool):
	health_component.take_damage(source, amount, is_headshot)

func deal_damage(target) -> void:
	if not can_attack: return
	if reactions_component.check_terminal_statuses(): return
	audio_stream_player.stream = hit_sound
	audio_stream_player.pitch_scale = randf_range(0.9, 1.1)
	audio_stream_player.play()
	Logger.log(parent_npc.npc_name, str("Атакую ", target.npc_name))
	var damage = attack_damage
	var is_headshot : bool = false
	if randi_range(0, 100) < 20:
		is_headshot = true
	target.combat_component.take_hit(target, damage, is_headshot)
	can_attack = false
	var attack_cooldown : float = randf_range(0.5, 1.0)
	$AttackCooldown.start(attack_cooldown)

func _on_health_knocked_out(is_knocked_out : bool) -> void:
	if is_knocked_out:
		if brawl_node.is_brawl_running:
			brawl_node.stop_brawl()

func _on_head_collision_body_entered(body: Node2D) -> void:
	if body.is_in_group("Throwable"):
		take_hit(body, body.deal_damage(), true)
		body.destroy()

func _on_body_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Throwable"):
		take_hit(body, body.deal_damage(), true)
		body.destroy()

func _on_attack_cooldown_timeout() -> void:
	can_attack = true
