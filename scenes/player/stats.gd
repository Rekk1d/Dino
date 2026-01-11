extends CanvasLayer

@export var heart_full: Texture2D
@export var heart_empty: Texture2D

@onready var hearts: Array[TextureRect] = []

func _ready() -> void:
	var container = get_child(0)
	for child in container.get_children():
		if child is TextureRect:
			hearts.append(child)	
	
	var player = get_parent()
	if player:
		player.connect("health_changed", Callable(self, "_on_health_changed"))
		update_hearts(player.health)


func _on_health_changed(current_health: int) -> void:
	update_hearts(current_health)
	
func update_hearts(current_health: int) -> void:
	for i in range(hearts.size()):
		if i < current_health:
			hearts[i].texture = heart_full
		else:
			hearts[i].texture = heart_empty
