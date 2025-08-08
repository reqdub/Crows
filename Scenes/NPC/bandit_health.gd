# npc_health.gd
extends Node2D
class_name Bandit_Health

# Exported variables for tweaking health values directly from the editor
var max_health_weak = 20
var max_health_normal = 25
var max_health_tough = 30

# Paths to nodes managed by this component (relative to its parent, the main NPC)
@onready var health_bar = %HealthBar
@onready var health_bar_label = $HealthBar/Label
@onready var on_screen_text_node = get_node("/root/World/OnScreenText")

# Resources
@onready var damage_indicator_prefab = preload("res://Scenes/damage_indicator.tscn")

var parent_npc : Bandit
var visual_component : Bandit_Visuals
var statemachine_component : StateMachine
var reactions_component : Bandit_Reactions
var karma_component : NPC_Karma

# Internal state variables for health
var current_health : int
var max_total_health : int
var knock_out_hp_treshhold : int

var damage_source_list : Array = []
# Status flags related to health
var is_damaged : bool = false
var is_head_damaged : bool = false
var is_body_damaged : bool = false
var is_dead : bool = false
var is_knockdown : bool = false

signal health_changed(amount: int)
signal damaged_by_hit(source_node: Node2D, is_headshot: bool) # Emitted when hit and damaged
signal critical_health() # Emitted when health drops below 3 (your original logic)
signal knocked_out(is_knocked_out : bool) # Emitted when health reaches 0 or critical threshold

enum Vitality {
	WEAK,
	NORMAL,
	TOUGH
}

func setup_component(_parent_npc, _visual_component, _statemachine_component, _karma_component, _reactions_component):
	parent_npc = _parent_npc
	visual_component = _visual_component
	statemachine_component = _statemachine_component
	karma_component = _karma_component
	reactions_component = _reactions_component
	
	visual_component.connect("knockdown_animation_finished", _on_knockdown_animation_finished)
	parent_npc.combat_component.connect("combat_started", _on_npc_combat_started)
	parent_npc.combat_component.connect("combat_ended", _on_npc_combat_ended)

func _ready() -> void:
	randomize_vitality()
	current_health = max_total_health
	knock_out_hp_treshhold = int(max_total_health * 0.1)
	if health_bar:
		health_bar.max_value = max_total_health
		health_bar.value = current_health
		health_bar.visible = false # Keep hidden initially as per your original script

func randomize_vitality() -> void:
	var random_vitality_type = randi_range(0, Vitality.size() - 1)
	match random_vitality_type:
		Vitality.WEAK:
			max_total_health = max_health_weak
		Vitality.NORMAL:
			max_total_health = max_health_normal
		Vitality.TOUGH:
			max_total_health = max_health_tough

func is_in_damager_list(damage_source) -> bool:
	if damage_source_list.has(damage_source): return true
	return false

func take_damage(source_node: Node2D, damage_amount: int, is_headshot: bool = false) -> void:
	if is_dead or is_knockdown:
		return
	if damage_amount == -1: return
	if not damage_source_list.has(source_node):
		damage_source_list.append(source_node)
	else:
		if source_node.is_in_group("Throwable"):
			source_node.disable()
	var health_before_damage_taken : int = current_health
	if damage_amount > 0:
		add_damage_indicator(damage_amount)
		current_health -= damage_amount
		if current_health < 0: current_health = 1
		is_damaged = true
		if health_bar:
			health_bar.visible = true
			health_bar.value = current_health
			if health_bar_label:
				health_bar_label.text = str(current_health, " / ", max_total_health)
		if is_headshot:
			is_head_damaged = true
			Logger.log(parent_npc.npc_name, str("Получено урона в голову ", damage_amount))
		else:
			is_body_damaged = true
			Logger.log(parent_npc.npc_name, str("Получено урона в туловище ", damage_amount))
		if health_bar:
			var health_tween = get_tree().create_tween()
			health_tween.tween_property(health_bar, "value", current_health, 0.3)
		if current_health <= knock_out_hp_treshhold:
			knock_out()
			return
		elif current_health <= 3:
			critical_health.emit()
		damaged_by_hit.emit(source_node, is_headshot)
		karma_component.calculate_karma(damage_amount, is_headshot, health_before_damage_taken, current_health, max_total_health)
	else:
		reactions_component._react_to_zero_damage()
		karma_component.calculate_karma(damage_amount, is_headshot, health_before_damage_taken,  current_health, max_total_health)
		add_damage_indicator(0)

func knock_out() -> void:
	is_knockdown = true
	health_bar.visible = false
	Logger.log(parent_npc.npc_name, "Получено слишком много урона, падаю без сознания")
	statemachine_component.change_state(statemachine_component.state.KNOCKDOWN)
	knocked_out.emit(true)

func _on_knockdown_animation_finished():
	is_knockdown = false
	knocked_out.emit(false)

func add_damage_indicator(amount: int) -> void:
	var damage_indicator_instance = damage_indicator_prefab.instantiate()
	damage_indicator_instance.setup(amount, Color.RED)
	damage_indicator_instance.global_position = get_node("%OnScreenIndicators").global_position
	on_screen_text_node.call_deferred("add_child", damage_indicator_instance)

func _on_head_collision_body_entered(body: Node2D) -> void:
	if body.is_in_group("Throwable"):
		take_damage(body, body.deal_damage(), true)
		body.destroy()

func _on_body_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Throwable"):
		take_damage(body, body.deal_damage(), true)
		body.destroy()

func _on_npc_combat_started():
	health_bar.visible = false

func _on_npc_combat_ended():
	if current_health < max_total_health:
		health_bar.visible = true
