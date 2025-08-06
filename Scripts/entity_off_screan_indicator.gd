extends Node2D

var is_active : bool

func _ready() -> void:
	$AnimationPlayer.play("fly")

func setup_indicator(_global_position):
	is_active = true
	self.global_position = _global_position

func delete_indicator():
	$AnimationPlayer.stop()
	self.queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Character"):
		if body.is_indicator_active:
			delete_indicator()
