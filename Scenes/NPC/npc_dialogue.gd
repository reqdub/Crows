# (Your speech display script, e.g., OnScreenText.gd or SpeechBubbleUI.gd)
extends Node2D
class_name NPC_Dialogue

var is_dialogues_blocked : bool = false
var text_display_time = 1.0
var bubble_show_time = 0.3
var delay_between_dialogs = 0.3 # You might not need this if managing single bubbles
var speech_tween : Tween

var npc_node

func _ready() -> void:
	# Ensure the bubble is hidden initially
	visible = false
	$Background/Label.set_text("")
	$Background/Label.visible_ratio = 0.0

func setup_component(_npc_node):
	npc_node = _npc_node
	npc_node.connect("say_phrase", _on_display_speech_requested)
	npc_node.combat_component.connect("combat_started", _on_npc_combat_started)
	npc_node.combat_component.connect("combat_ended", _on_npc_combat_ended)

func _on_display_speech_requested(npc_name, type: String):
	if is_dialogues_blocked: return
	# This check ensures we don't start a new tween if one is already active,
	# or you might want to stop the existing one.
	if speech_tween and speech_tween.is_running():
		return
	var random_text = SpeechReplicas.random_dialogue(type)
	# Log with NPC name for clarity
	Logger.log(npc_name, " говорит: " + random_text)
	
	visible = true
	$Background/Label.set_text(random_text)
	$Background/Label.visible_ratio = 0.0 # Start from 0 for the tween

	speech_tween = create_tween()
	speech_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT) # Add some easing
	speech_tween.tween_property($Background/Label, "visible_ratio", 1.0, bubble_show_time)
	
	# Wait for the tween to finish and then for the bubble_show_time
	await speech_tween.finished
	# Add an additional short delay after text fully appears before hiding
	await get_tree().create_timer(text_display_time).timeout 
	
	$Background/Label.set_text("") # Clear text
	visible = false # Hide the bubble

func _on_npc_combat_started():
	is_dialogues_blocked = true
	visible = false
func _on_npc_combat_ended():
	is_dialogues_blocked = false
