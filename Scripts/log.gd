extends ColorRect

class_name log

@onready var log_text : RichTextLabel = $MarginContainer/ColorRect/MarginContainer/LogText

func add_text_to_log(text : String):
	
	log_text.append_text(text)
	log_text.append_text("\n")

func _ready() -> void:
	Logger.setup_log(self)

func _on_button_pressed() -> void:
	visible = !visible
