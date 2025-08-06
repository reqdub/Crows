# npc_combat.gd
extends Node
class_name NPC_Combat

# References to scene nodes needed for combat (e.g., Brawl node, weapon spawns)
@onready var brawl_node : Brawl = get_node("/root/World/Brawl") # Global node
@onready var drop_position = %LootDropPosition # To drop loot on death/knockout

var parent_npc
var vision_component : NPC_Vision
var statemachine_node : StateMachine
var health_component : NPC_Health
var reactions_component : NPC_Reactions
var movement_component : NPC_Movement
# Combat specific variables
@export var base_karma_damage : int = 10 # Example default, adjust as needed
@export var damage_taking_karma_factor : float = 2.0
@export var panic_karma_factor : float = 1.0

@export var delay_before_start_fight : float = 0.5
@export var attack_damage : int = 10 # Damage this NPC deals
@export var attack_cooldown : float = 1.0 # How often this NPC can attack

var target_enemy : Node2D = null
var is_in_fight : bool = false
var is_enemy_in_sight : bool = false
var potential_enemy : Node2D = null
var is_enemy_been_seeing: bool = false
var last_attack_time : float = 0.0

# Signals for other components/systems to react to combat events
signal combat_started(with : Node2D)
signal combat_ended(winner : bool)
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

func initiate_combat(enemy_node: Node2D) -> void:
	if is_in_fight or health_component.is_dead or health_component.is_knockdown: return
	target_enemy = enemy_node
	is_in_fight = true
	Logger.log(parent_npc.name, str("Начинаю бой с ", target_enemy.name))
	vision_component.set_vision(false)
	parent_npc.dialogue_component.visible = false
	health_component.health_bar.visible = false

func start_combat():
	combat_started.emit(target_enemy)

func end_combat(won: bool) -> void:
	if not is_in_fight: return
	is_in_fight = false
	target_enemy = null
	Logger.log(parent_npc.name, str("Бой завершился, я победил? ", won))
	if won:
		parent_npc.is_angry = false
		parent_npc.say("taunt")
		statemachine_node.change_state(statemachine_node.state.WALK)
	else:
		pass 
	combat_ended.emit(won)

func start_brawl():
	await brawl_node.start_brawl(parent_npc, target_enemy)
# Function called when NPC decides to attack

func perform_attack() -> void:
	if not is_in_fight or not target_enemy: return
	#if Engine.get_process_time() - last_attack_time < attack_cooldown: return
	#last_attack_time = Engine.get_process_time()
	Logger.log(parent_npc.name, str("Атакую ", target_enemy.name))
	parent_npc.visuals_component.animation_player.play("Attack") 
	# This assumes the target_enemy has a 'take_damage' method
	if target_enemy.has_method("take_damage"):
		target_enemy.take_damage(parent_npc, attack_damage)
		attacked_target.emit(target_enemy, attack_damage)
	else:
		Logger.warn(str("Target enemy ", target_enemy.name, " does not have a 'take_damage' method."))
	# Wait for animation to finish before potentially moving or another action
	await parent_npc.visuals_component.animation_player.animation_finished
	# After attacking, NPC might go back to a combat idle or pursue
	statemachine_node.change_state(statemachine_node.state.IDLE) # Or whatever state after attack

func _on_health_knocked_out(is_knocked_out : bool) -> void:
	# When NPC is knocked out, combat naturally ends.
	if is_knocked_out:
		if brawl_node.is_brawl_running:
			brawl_node.stop_brawl()
		end_combat(false) # NPC lost the fight
	# Drop loot and handle collision cleanup (gameplay concern, not purely combat but often tied to it)
	#parent_npc.drop_ammunition(true)
	# These collision shape removals are critical for gameplay (no longer interactable)
	# They are part of the "knockout" process, which is a result of combat (or severe damage).
	# Keep them here for now, or move to a dedicated "NPC_State_Cleanup" component if it gets larger.
	else:
		if parent_npc.get_node_or_null("Visual/Body/BodyArea"):
			parent_npc.get_node("Visual/Body/BodyArea").queue_free()
		if parent_npc.get_node_or_null("Visual/Head/HeadCollision"):
			parent_npc.get_node("Visual/Head/HeadCollision").queue_free()
	# The actual state change to KNOCKDOWN will be handled by the StateMachine,
	# which is already connected to health_component.knocked_out in npc.gd.
	# So, no need to `change_state` here.
