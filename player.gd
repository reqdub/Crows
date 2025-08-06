extends Node2D

class_name player

@onready var throwable_item = preload("res://Scenes/Items/Throwable_Item.tscn")
@onready var throwable_area = get_node("/root/World/Background/Walk_Area")

@onready var drop_area = get_node("/root/World/Background/Walk_Area")
@onready var drop = preload("res://item.tscn")

@onready var throw_sound = load("res://Sounds/SFX/throw.wav")
@onready var stun_sound = load("res://Sounds/SFX/stun.ogg")

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
var is_pray_cancelled : bool = false
var is_in_stealth : bool = false
var is_damaged : bool = false
var is_knockdown = false
var is_praying : bool = false
var is_in_battle : bool = false

enum state {
	IDLE,
	FIGHT,
	STEALTH,
	KNOCKDOWN
}
var current_state = state.IDLE

func _ready() -> void:
	initial_position = self.global_position
	change_state(state.IDLE)
	look_right()

func change_state(new_state):
	exit_state()
	enter_state(new_state)

func enter_state(new_state):
	match new_state:
		0 : #IDLE
			idle_state()
		1 : #FIGHT
			block_player_control.emit(true)
			fight_state()
		2 : #STEALTH
			stealth_state()
		3:#KNOCKDOWN
			block_player_control.emit(true)
			$Visual/Head.frame = 3
			knockdown_state()
func exit_state():
	match current_state:
		0 : #IDLE
			pass
		1 : #FIGHT
			block_player_control.emit(false)
		2 : #STEALTH
			pass
		3:#KNOCKDOWN
			$Visual/Head.frame = 2
			block_player_control.emit(false)

func idle_state():
	current_state = state.IDLE
	$AnimationPlayer.play("Idle")
func fight_state():
	current_state = state.FIGHT
func stealth_state():
	current_state = state.STEALTH
	is_in_stealth = true
func knockdown_state():
	current_state = state.KNOCKDOWN
	Logger.log("Игрок ", " в нокдауне")
	is_knockdown = true
	$AudioStreamPlayer.stream = stun_sound
	$AudioStreamPlayer.play()
	$AnimationPlayer.play("Knockdown")
	await $AnimationPlayer.animation_finished
	is_knockdown = false
	change_state(state.IDLE)

func blink():
	var blink_chance = 50
	if blink_chance <= randi_range(0, 100): return
	var timer = get_tree().create_timer(0.4)
	if is_damaged:
		$Visual/Head.frame = 2
		await timer.timeout
		$Visual/Head.frame = 3
	else:
		$Visual/Head.frame = 1
		await timer.timeout
		$Visual/Head.frame = 0

func throw_item():
	var throwable_instance = throwable_item.instantiate()
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
	if current_state == state.STEALTH: return
	change_state(state.STEALTH)
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
	if is_knockdown: return
	if is_in_battle: return
	change_state(state.IDLE)

func cancel_all_actions():
	if current_state == state.STEALTH:
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

func pray():
	block_player_control.emit(true)
	await walk_to(statue)
	is_praying = true
	$AnimationPlayer.play("Pray")
	await $AnimationPlayer.animation_finished
	is_praying = false
	emit_signal("pray_finished")
	$AnimationPlayer.stop()
	await walk_to(initial_position)
	block_player_control.emit(false)

func cancel_pray():
	is_pray_cancelled = true
	$Timer.stop()
	if movement_tween:
		movement_tween.kill()
	is_pray_cancelled = false

func stop_praying():
	$AnimationPlayer.stop()
	cancel_pray()
	is_praying = false

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

func start_combat():
	if is_praying:
		stop_praying()
	Logger.log("Player ", "начинает бой")
	is_in_battle = true
	change_state(state.FIGHT)
func end_combat(win : bool, winner = null):
	if winner != null and winner.is_in_group("Guard"):
		is_criminal_scum = false
		criminal.emit(false)
		drop_loot(winner)
	Logger.log("Player ", "заканчивает бой")
	is_in_battle = false
	if win: change_state(state.IDLE)
	else:
		is_damaged = true
		$Visual/Head.frame = 2
		change_state(state.KNOCKDOWN)
	if not is_player_in_initial_position:
		block_player_control.emit(true)
		await walk_to(initial_position)
		block_player_control.emit(false)

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
	if current_state != state.STEALTH: return false
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
	$Label.set_text(str(state.keys()[current_state]))

func _on_prescence_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Empty_Space"):
		await get_tree().create_timer(0.5).timeout
		is_player_in_initial_position = true

func _on_prescence_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Empty_Space"):
		await get_tree().create_timer(0.5).timeout
		is_player_in_initial_position = false
