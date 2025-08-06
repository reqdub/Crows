# npc_visuals.gd
extends Node2D
class_name Guard_Visuals

# References to visual child nodes of the main NPC
@onready var visual_node = $"../Visual"
@onready var head_sprite = $"../Visual/Head"
@onready var body_sprite = $"../Visual/Body"
@onready var animation_player = $"../AnimationPlayer"
# Reference to the parent NPC script to get state information if needed
var parent_npc
var npc_type
var health_component : Guard_Health

# Internal state for visuals
var current_head_frame = 0 # To track default/damaged head frame
var is_blink_active = false

signal knockdown_animation_finished

func _ready() -> void:
	randomize_visual()

func setup_component(_parent_npc, _health_component, _npc_type) -> void:
	parent_npc = _parent_npc
	npc_type = _npc_type
	health_component = _health_component
	health_component.damaged_by_hit.connect(_on_health_damaged_by_hit)
	health_component.knocked_out.connect(_on_health_knocked_out)

func randomize_visual() -> void:
	var head_texture_path
	match npc_type:
		0: #PEASANT
			var random_head = randi_range(1, 3)
			head_texture_path = "res://Sprites/NPC/Heads/Male/Head" + str(random_head) + ".png"
			head_sprite.texture = load(head_texture_path)
			head_sprite.frame = 0
			current_head_frame = 0 # Reset for future use if needed
		1: #GUARD
			pass

# --- Animation Playback Functions ---
func play_walk_animation() -> void:
	if animation_player:
		if parent_npc.is_panic:
			play_panic_animation()
		else:
			animation_player.play("Walk")

func play_chase_animation() -> void:
	# Often same as walk, but could be different if you have a distinct chase animation
	if animation_player:
		animation_player.play("Walk") # Or "Chase" if you create one

func play_idle_animation() -> void:
	if animation_player:
		animation_player.stop() # Or play "Idle" if you have one

func play_panic_animation() -> void:
	if animation_player:
		animation_player.play("Panic")

func play_caution_animation() -> void:
	if animation_player:
		animation_player.stop() # Or play "Caution" if you have one

func play_knockdown_animation() -> void:
	if animation_player:
		animation_player.play("Knockdown")
		await animation_player.animation_finished
		Logger.log(parent_npc.npc_name, " анимация нокдауна окончена")
		knockdown_animation_finished.emit()
		# In your original script, Knockdown also hid UI and freed collision shapes.
		# Those actions should remain in the main NPC (or a dedicated cleanup component)
		# as they are not purely visual but also gameplay-affecting.
		# This component's job is just to play the animation.
		
		# Original: await $AnimationPlayer.animation_finished
		# The main NPC (or StateMachine) should await this if needed for state transition.
		# This component just plays the animation.

func stop_all_animations() -> void:
	if animation_player:
		animation_player.stop()

# --- Damage Visuals ---
func _on_health_damaged_by_hit(_source_node: Node2D, _is_headshot: bool) -> void:
	update_damage_visuals()

func update_damage_visuals() -> void:
	if health_component.is_head_damaged and head_sprite:
		head_sprite.frame = 3 # Damaged head frame
	if health_component.is_body_damaged and body_sprite:
		body_sprite.frame = 1 # Damaged body frame

func _on_health_knocked_out(is_knocked__out : bool) -> void:
	if is_knocked__out:
		play_knockdown_animation()
		head_sprite.frame = 3 # Head damaged on knockout (as per original)
		body_sprite.frame = 1 # Body damaged on knockout (as per original)

# --- Blink Animation (specific head frame change) ---
func blink() -> void:
	if is_blink_active: return # Prevent multiple blinks at once
	var blink_chance = 50
	if dice_roll() <= blink_chance:
		is_blink_active = true
		var timer = get_tree().create_timer(0.4)
		if health_component.is_head_damaged and head_sprite:
			head_sprite.frame = 2 # Partially closed damaged eye
			await timer.timeout
			head_sprite.frame = 3 # Back to damaged head
		elif head_sprite: # Not damaged
			head_sprite.frame = 1 # Partially closed eye
			await timer.timeout
			head_sprite.frame = 0 # Back to default head
		is_blink_active = false

func dice_roll() -> int:
	return randi_range(0, 100)
