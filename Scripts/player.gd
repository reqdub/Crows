extends Node2D

class_name player

@onready var throwable_item = preload("res://Scenes/Items/Throwable_Item.tscn")
@onready var throwable_area = get_node("/root/World/Background/Walk_Area")

@onready var drop_area = get_node("/root/World/Background/Walk_Area")
@onready var drop = preload("res://Scenes/item.tscn")

@onready var throw_sound = load("res://Sounds/SFX/throw.wav")

@onready var health_component = %Health_Component
@onready var combat_component = %Combat_Component
@onready var visual_component = %Visual_Component
@onready var statemachine_component = %Statemachine

@export var throw_cooldown : float = 2.0

signal block_player_control(blocked : bool)
signal pray_finished
signal item_dropped(item_name, item_amount)
signal criminal(is_scum : bool)

enum look_side {
	LEFT,
	RIGHT
}
var looking_at = look_side.LEFT
var switch_look_direction_cooldown : float = 2.0

var is_looking_on_cooldown : bool = false
var looking_timer : SceneTreeTimer
var movement_tween : Tween
var stealth_tween : Tween
var initial_position : Vector2
var statue : Vector2

var walk_speed = 3
var is_throw_on_cooldown : bool = false
var throw_strength : float
var stealth_chance : int = 80

var is_criminal_scum : bool = false
var is_player_in_initial_position : bool = true
var is_in_stealth : bool = false

func _ready() -> void:
	setup_components()
	initial_position = self.global_position
	statemachine_component.change_state(statemachine_component.state.IDLE)
	look_right()

func setup_components():
	health_component.setup_component(self, combat_component, visual_component, statemachine_component)
	combat_component.setup_component(self, health_component, visual_component, statemachine_component)
	visual_component.setup_component(self)
	statemachine_component.setup_component(self, health_component, visual_component)

func blink():
	var blink_chance = 50
	if blink_chance <= randi_range(0, 100): return
	var timer = get_tree().create_timer(0.4)
	if health_component.is_damaged:
		$Visual/Head.frame = 2
		await timer.timeout
		$Visual/Head.frame = 3
	else:
		$Visual/Head.frame = 1
		await timer.timeout
		$Visual/Head.frame = 0

func throw_item():
	var throwable_instance = throwable_item.instantiate()
	throwable_instance.set_item(combat_component.current_weapon_type, combat_component.base_damage)
	throwable_instance.global_position = %ThrowPosition.global_position
	throwable_instance.throw_strength = self.throw_strength
	throwable_area.add_child(throwable_instance)
	
func throw(strength : float, angle: float):
	if is_throw_on_cooldown : return
	if angle > 0 and angle < 2.4:
		look_left()
	else: look_right()
	throw_strength = strength
	$AnimationPlayer.play("Throw")
	$AudioStreamPlayer.stream = throw_sound
	$AudioStreamPlayer.play()
	$Timer.start(throw_cooldown)
	is_throw_on_cooldown = true
	await $AnimationPlayer.animation_finished
	
func _on_timer_timeout() -> void:
	$Visual/RightHand/Weapon.visible = true
	is_throw_on_cooldown = false

func stealth():
	if statemachine_component.current_state == statemachine_component.state.STEALTH: return
	statemachine_component.change_state(statemachine_component.state.STEALTH)
	$Stealth.visible = true
	$CollisionShape2D.set_deferred("disabled", true)
	$CollisionShape2D.set_deferred("disabled", false)
	stealth_tween = get_tree().create_tween()
	stealth_tween.tween_property($Visual, "modulate", Color.from_rgba8(255,255,255,60), 0.5)

func remove_stealth():
	is_in_stealth = false
	if stealth_tween != null:
		stealth_tween.kill()
	$Stealth.visible = false
	$Visual.modulate = Color.from_rgba8(255,255,255,255)
	$CollisionShape2D.set_deferred("disabled", true)
	$CollisionShape2D.set_deferred("disabled", false)
	if health_component.is_knockdown: return
	if combat_component.is_in_battle: return
	statemachine_component.change_state(statemachine_component.state.IDLE)

func cancel_all_actions():
	if statemachine_component.current_state == statemachine_component.state.STEALTH:
		remove_stealth()
		$Visual/RightHand/Weapon.visible = false

func walk_to(to : Vector2):
	if global_position.x > to.x:
		look_left()
	else:
		look_right()
	movement_tween = get_tree().create_tween()
	movement_tween.tween_property(self, "global_position", to, walk_speed)
	$AnimationPlayer.play("Walk")
	await movement_tween.finished
	$AnimationPlayer.stop()

func become_criminal():
	is_criminal_scum = true
	criminal.emit(true)

func drop_loot(loot_collector):
	var player_inventory = Inventory.player_inventory
	for item in player_inventory:
		var item_name = item
		var item_amount = player_inventory[item]
		item_dropped.emit(item_name, -item_amount)
		for i in item_amount:
			var droppable_item_instance : droppable_item = drop.instantiate()
			droppable_item_instance.set_item(item_name, loot_collector)
			droppable_item_instance.global_position = self.global_position
			drop_area.call_deferred("add_child", droppable_item_instance)

func look_left():
	looking_at = look_side.LEFT
	$Visual.scale.x = -1
func look_right():
	looking_at = look_side.RIGHT
	$Visual.scale.x = 1

func look_at_target(target):
	Logger.log("Игрок ", " поворачивается к NPC")
	if is_looking_on_cooldown: return
	is_looking_on_cooldown = true
	if target.global_position.x > global_position.x:
		if looking_at == look_side.RIGHT: return
		look_right()
		Logger.log("Игрок ", " поворачивается направо")
	else:
		if looking_at == look_side.LEFT: return
		look_left()
		Logger.log("Игрок ", " поворачивается налево")
	looking_timer = get_tree().create_timer(switch_look_direction_cooldown)
	await looking_timer.timeout
	is_looking_on_cooldown = false

func check_stealth(difficulty_modifier : float = 1.0) -> bool:
	if statemachine_component.current_state != statemachine_component.state.STEALTH: return false
	Logger.log("Игрок ", str("Проходит проверку скрытности"))
	var random_chance = randi_range(1, 100)
	var stealth_value = stealth_chance / difficulty_modifier
	if random_chance <= stealth_value:
		Logger.log("Игрок ", str("прошёл проверку скрытности, выкинув", stealth_value, " против ", random_chance))
		return true
	Logger.log("Игрок ", str("провалил проверку скрытности, выкинув", stealth_value, " против ", random_chance))
	remove_stealth()
	return false
func _process(_delta: float) -> void:
	$Label.set_text(str(statemachine_component.state.keys()[statemachine_component.current_state]))

func _on_prescence_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Empty_Space"):
		await get_tree().create_timer(0.5).timeout
		is_player_in_initial_position = true

func _on_prescence_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Empty_Space"):
		await get_tree().create_timer(0.5).timeout
		is_player_in_initial_position = false
