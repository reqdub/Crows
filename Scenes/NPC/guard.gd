extends CharacterBody2D

class_name Guard

@export var dialogues : Resource
# @export var walk_speed = randi_range(500, 1000) # Now in NPC_Movement

@onready var loot = preload("res://item.tscn")
@onready var signal_bus = get_node("/root/World/Signal_Bus")
@onready var statemachine_node : StateMachine = %StateMachine
@onready var danger_point = get_node("/root/World/Background/DangerPoint")

@onready var on_screen_text = get_node("/root/World/OnScreenText")

# --- ADD REFERENCES TO NEW COMPONENTS ---
@onready var dialogue_component : NPC_Dialogue = %Dialogue
@onready var health_component : Guard_Health = %Health
@onready var reactions_component : Guard_Reactions = %Reactions
@onready var visuals_component : Guard_Visuals = %Visuals
@onready var combat_component : Guard_Combat = %Combat
@onready var movement_component : NPC_Movement = %Movement
@onready var vision_component : Guard_Vision = %Vision
@onready var loot_component : NPC_Loot = %Loot
@onready var inventory_component : NPC_Inventory = %Inventory
@onready var karma_component : NPC_Karma = %Karma
@onready var ammunition_component : NPC_Ammunition = %Ammunition
# ----------------------------------------

@onready var drop_position = %LootDropPosition
var spawn_position
var despawn_position
var npc_name = "George"
enum npc_type {
	PEASANT,
	GUARD
}
var current_npc_type
signal say_phrase(_npc_name, _text)

# Keep these global NPC states here for now, if they're not directly managed by components
var is_angry : bool = false
var is_panic : bool = false

func _ready() -> void:
	randomize()
	drop_position = %LootDropPosition
	setup_components()
	statemachine_node.change_state(statemachine_node.state.WALK)

func setup_components():
	%Reactions.setup_component(self, statemachine_node, health_component, movement_component, combat_component, vision_component, visuals_component)
	%Combat.setup_component(self, statemachine_node, movement_component, health_component, reactions_component, vision_component)
	%Visuals.setup_component(self, health_component, current_npc_type)
	%Health.setup_component(self, visuals_component, statemachine_node, karma_component, reactions_component)
	%Movement.setup_component(self, statemachine_node, reactions_component, health_component, visuals_component)
	%StateMachine.setup_component(self, %Actions, health_component, combat_component, movement_component)
	%Dialogue.setup_component(self)
	%Vision.setup_component(self, health_component, combat_component, reactions_component)
	%Inventory.setup_component(self)
	%Loot.setup_component(self, inventory_component)
	%Karma.setup_component(self)

func setup_npc(_npc_type : npc_type, _spawn_point, _despawn_point):
	spawn_position = _spawn_point
	despawn_position = _despawn_point
	current_npc_type = _npc_type
	self.global_position = _spawn_point.global_position

func say(phrase_type : String):
	say_phrase.emit(npc_name, phrase_type)

func _physics_process(delta: float) -> void:
	if velocity != Vector2.ZERO:
		move_and_slide()

func set_movement(direction : Vector2, movement_speed : float):
	velocity = direction * movement_speed

func _process(delta: float) -> void:
	$DebugLabel.set_text(str(movement_component.walk_speed))

func _on_collect_area_body_entered(body: Node2D) -> void:
	body.destroy()
