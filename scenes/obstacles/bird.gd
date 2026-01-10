extends Area2D

func _process(_delta: float) -> void:
	position.x -= get_parent().speed / 2
