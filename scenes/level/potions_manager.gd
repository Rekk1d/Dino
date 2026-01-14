extends Node2D
class_name PotionsManager

var hp_potion = preload("res://scenes/collectibles/hp_potion.tscn")

var potion_types := [hp_potion]
var potions: Array

# Constants
const MIN_POTION_DISTANCE: int = 400 
const MIN_DISTANCE_FROM_OBSTACLE: int = 100

# References
var camera: Camera2D
var player: CharacterBody2D
var parent_node: Node2D
var ground_top_y: float
var screen_size: Vector2i
var obstacles_manager: ObstaclesManager

var last_potion_x: float = 0.0 
var spawn_chance: float = 0.01 

func setup(p_camera: Camera2D, p_player: CharacterBody2D, p_parent: Node2D, p_ground_top_y: float, p_screen_size: Vector2i, p_obstacles_manager: ObstaclesManager) -> void:
	camera = p_camera
	player = p_player
	parent_node = p_parent
	ground_top_y = p_ground_top_y
	screen_size = p_screen_size
	obstacles_manager = p_obstacles_manager

func reset() -> void:
	for potion in potions:
		if is_instance_valid(potion):
			potion.queue_free()
	potions.clear()
	last_potion_x = 0.0

func generate_potions() -> void:
	if not camera or not parent_node or not obstacles_manager:
		return
	
	var min_distance_passed = potions.is_empty() or (last_potion_x < camera.position.x - MIN_POTION_DISTANCE)
	
	if min_distance_passed:
		if randf() < spawn_chance:
			var camera_right_edge = camera.position.x + screen_size.x / 2.0
			var potion_x = camera_right_edge + randf_range(100, 200)
		
			if is_position_safe(potion_x):
				spawn_potion(potion_x)

func is_position_safe(potion_x: float) -> bool:
	for obstacle in obstacles_manager.obstacles:
		if is_instance_valid(obstacle):
			var distance = abs(obstacle.position.x - potion_x)
			if distance < MIN_DISTANCE_FROM_OBSTACLE:
				return false
	return true

func spawn_potion(potion_x: float) -> void:
	var potion_type = potion_types[randi() % potion_types.size()]
	var potion = potion_type.instantiate()
	
	var sprite: AnimatedSprite2D = potion.get_node("AnimatedSprite2D")
	var frame_texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	var potion_height = frame_texture.get_height()
	var potion_scale = sprite.scale
	
	var potion_y = ground_top_y - (potion_height * potion_scale.y / 2)
	
	potion.position = Vector2(potion_x, potion_y)
	potion.body_entered.connect(_on_potion_collected)
	parent_node.add_child(potion)
	potions.append(potion)
	last_potion_x = potion_x

func _on_potion_collected(body) -> void:
	if body.name == player.name:
		for potion in potions:
			if is_instance_valid(potion) and potion.has_overlapping_bodies():
				var overlapping = potion.get_overlapping_bodies()
				if body in overlapping:
					if potion.scene_file_path == hp_potion.resource_path:
						Signals.emit_signal("health_recover")
					# elif potion.scene_file_path == speed_potion.resource_path:
					#     Signals.emit_signal("speed_boost")
					potions.erase(potion)
					potion.queue_free()
					break
	
func cleanup_potions() -> void:
	if not camera:
		return
		
	var camera_left_edge = camera.position.x - screen_size.x / 2.0
	for i in range(potions.size() - 1, -1, -1):
		var potion = potions[i]
		if is_instance_valid(potion) and potion.position.x < camera_left_edge - 100:
			potions.remove_at(i)
			potion.queue_free()
