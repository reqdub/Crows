extends Node2D

@onready var trees: Array = $Trees.get_children()
@onready var bushes: Array = $Bushes.get_children()

func _ready():
	for tree in trees:
		if not tree.material:
			push_warning("Sprite %s has no material" % tree.name)
			continue
		tree.material = tree.material.duplicate()
		tree.material.set_shader_parameter("speed", randf_range(0.4, 1.0))
	for bush in bushes:
		if not bush.material:
			push_warning("Sprite %s has no material" % bush.name)
			continue
		bush.material = bush.material.duplicate()
		bush.material.set_shader_parameter("speed", randf_range(0.4, 1.0))
