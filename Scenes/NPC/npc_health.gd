# npc_health.gd
extends Node2D
class_name NPC_Health

@onready var health_bar = %HealthBar
@onready var health_bar_label = $HealthBar/Label
@onready var on_screen_text_node = get_node("/root/World/OnScreenText")
@onready var damage_indicator_prefab = preload("res://Scenes/damage_indicator.tscn")

var max_health_weak = 10
var max_health_normal = 15
var max_health_tough = 25

var damage_source_list : Array = []

var parent_npc
var visual_component
var statemachine_component : StateMachine
var reactions_component
var karma_component : NPC_Karma

# Internal state variables for health
var current_health : int
var max_total_health : int
var knock_out_hp_treshhold : int
# Status flags related to health
var is_damaged : bool = false
var is_head_damaged : bool = false
var is_body_damaged : bool = false
var is_dead : bool = false
var is_knockdown : bool = false

signal health_changed(amount: int)
signal damaged_by_hit(source_node: Node2D, is_headshot: bool) # Emitted when hit and damaged
signal critical_health() # Emitted when health drops below 3 (your original logic)
signal knocked_out(is_knocked_out : bool, by_who : Node2D) # Emitted when health reaches 0 or critical threshold

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

func take_damage(source_node: Node2D, damage_amount: int, is_headshot: bool = false) -> void:
	if is_dead or is_knockdown:
		return
	if damage_amount == -1: return
	if source_node.is_in_group("Throwable"):
		source_node.disable()
		var thrower = source_node.thrower
		source_node = source_node.thrower
		if not damage_source_list.has(thrower):
			damage_source_list.append(thrower)
	else:
		if not damage_source_list.has(source_node):
			damage_source_list.append(source_node)
	var health_before_damage_taken : int = current_health
	if damage_amount > 0:
		AudioManager.play_sound(SoundCache.hit_sound)
		add_damage_indicator(damage_amount)
		current_health -= damage_amount
		if current_health <= 0: current_health = 1
		is_damaged = true
		if health_bar:
			health_bar.visible = true
			health_bar.value = current_health
			if health_bar_label:
				health_bar_label.text = str(current_health, " / ", max_total_health)
		var parent_name = get_parent().name
		if is_headshot:
			is_head_damaged = true
			Logger.log(parent_name, str("Получено урона в голову ", damage_amount))
		else:
			is_body_damaged = true
			Logger.log(parent_name, str("Получено урона в туловище ", damage_amount))
		var health_tween = get_tree().create_tween()
		health_tween.tween_property(health_bar, "value", current_health, 0.3)
		if current_health <= knock_out_hp_treshhold:
			karma_component.calculate_karma(damage_amount, is_headshot, health_before_damage_taken, current_health, max_total_health)
			knock_out(damage_source_list[-1])
			return
		elif current_health <= 3:
			critical_health.emit()
		damaged_by_hit.emit(source_node, is_headshot)
		if source_node.is_in_group("Player") or source_node.is_in_group("Throwable"):
			karma_component.calculate_karma(damage_amount, is_headshot, health_before_damage_taken, current_health, max_total_health)
	else:
		reactions_component._react_to_zero_damage()
		add_damage_indicator(0)
		if source_node.is_in_group("Player") or source_node.is_in_group("Throwable"):
			karma_component.calculate_karma(damage_amount, is_headshot, health_before_damage_taken,  current_health, max_total_health)

func knock_out(by_who : Node2D) -> void:
	is_knockdown = true
	health_bar.visible = false
	Logger.log(parent_npc.npc_name, "Получено слишком много урона, падаю без сознания")
	statemachine_component.change_state(statemachine_component.state.KNOCKDOWN)
	knocked_out.emit(true, by_who)

func _on_knockdown_animation_finished():
	is_knockdown = false
	knocked_out.emit(false, damage_source_list[-1])

func add_damage_indicator(amount: int) -> void:
	if not damage_indicator_prefab:
		Logger.error("Damage indicator prefab not loaded!")
		return
	var damage_indicator_instance = damage_indicator_prefab.instantiate()
	damage_indicator_instance.setup(amount, Color.RED)
	if on_screen_text_node and get_node_or_null("%OnScreenIndicators"):
		damage_indicator_instance.global_position = get_node("%OnScreenIndicators").global_position
		on_screen_text_node.call_deferred("add_child", damage_indicator_instance)
	else:
		Logger.warn("OnScreenText node or %OnScreenIndicators not found for damage indicator. Placing at NPC position.")
		# Fallback if the target UI nodes aren't found
		damage_indicator_instance.global_position = get_parent().global_position
		on_screen_text_node.add_child(damage_indicator_instance) # Add to root if no specific UI parent

func _on_npc_combat_started():
	health_bar.visible = false

func _on_npc_combat_ended():
	if current_health < max_total_health:
		health_bar.visible = true
