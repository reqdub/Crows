extends Node2D

var bubble_show_time = 1.5
var delay_between_dialogs = 0.3
var speech_tween : Tween

func _ready() -> void:
	%Character.connect("display_speech", _on_display_speech)

func _on_display_speech(_text: String):
	Logger.log(get_parent().walker_name, " говорит: " + _text)
	visible = true
	$Background/Label.set_text(_text)
	speech_tween = get_tree().create_tween()
	speech_tween.tween_property($Background/Label, "visible_ratio", 1.0, 1.5)
	await get_tree().create_timer(bubble_show_time).timeout
	$Background/Label.set_text("")
	visible = false
