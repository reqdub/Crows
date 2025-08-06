extends Node2D

class_name Player_Health

@onready var on_screen_text_node = get_node("/root/World/OnScreenText")
@onready var damage_indicator = preload("res://Scenes/damage_indicator.tscn")
@onready var health_bar = $HealthBar

var parent
var combat_component
var visual_component
var statemachine

var current_health : int
var max_total_health : int = 20
var regen_amount : int = 1
var regen_timeout : float = 2.5

var is_damaged : bool = false
var is_head_damaged : bool = false
var is_body_damaged : bool = false
var is_dead : bool = false
var is_knockdown : bool = false

func _ready() -> void:
	current_health = max_total_health
	$HealthBar.max_value = max_total_health
	$HealthBar.value = current_health
	$HealthBar/Label.set_text(str(current_health, " / ", max_total_health))

func setup_component(_parent, _combat_component, _visual_component, _statemachine):
	parent = _parent
	combat_component = _combat_component
	visual_component = _visual_component
	statemachine = _statemachine

func take_damage(amount):
	current_health -= amount
	if current_health <= 0:
		current_health = 1
	update_health_bar()
	add_damage_indicator(amount, Color.YELLOW)
	if current_health < 5:
		knocked_out()

func update_health_bar():
	if current_health < max_total_health:
		$HealthBar.visible = true
		var health_bar_tween = create_tween()
		health_bar_tween.tween_property(health_bar, "value", current_health, 0.3)
		$HealthBar/Label.set_text(str(current_health, " / ", max_total_health))

func knocked_out():
	statemachine.change_state(statemachine.state.KNOCKDOWN)

func _on_regen_timer_timeout() -> void:
	regenerate_health()
	$RegenTimer.start(regen_timeout)

func regenerate_health():
	if combat_component.is_in_battle: return
	if current_health >= max_total_health: return
	current_health += regen_amount
	update_health_bar()
	add_damage_indicator(regen_amount, Color.GREEN)

func add_damage_indicator(amount, color):
	var damage_indicator_instance = damage_indicator.instantiate()
	damage_indicator_instance.global_position = $IndicatorPosition.global_position
	damage_indicator_instance.setup(amount, color)
	on_screen_text_node.call_deferred("add_child", damage_indicator_instance)
