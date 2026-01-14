extends Node
class_name ObstaclesManager

# Obstacles
var box_scene = preload("res://scenes/obstacles/box.tscn")
var barrel_scene = preload("res://scenes/obstacles/barrel.tscn")
var bird_scene = preload("res://scenes/obstacles/bird.tscn")
var obstacles_types := [box_scene, barrel_scene]
var obstacles: Array
var bird_heights = [125, 170]

# Constants
const MIN_OBSTACLE_DISTANCE: int = 200
const MAX_OBSTACLE_DISTANCE: int = 500
const MAX_DIFFICULTY: int = 1

# References
var camera: Camera2D
var player: CharacterBody2D
var parent_node: Node2D
var ground_top_y: float
var screen_size: Vector2i

var last_obstacle
var difficulty: int = 0

func setup(p_camera: Camera2D, p_player: CharacterBody2D, p_parent: Node2D, p_ground_top_y: float, p_screen_size: Vector2i) -> void:
	camera = p_camera
	player = p_player
	parent_node = p_parent
	ground_top_y = p_ground_top_y
	screen_size = p_screen_size

func reset() -> void:
	for obs in obstacles:
		if is_instance_valid(obs):
			obs.queue_free()
	obstacles.clear()
	last_obstacle = null
	difficulty = 0

func update_difficulty(score: int, speed_modifier: int) -> void:
	difficulty = score / speed_modifier
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

func generate_obstacles() -> void:
	if not camera or not parent_node:
		return
		
	if obstacles.is_empty() or (last_obstacle != null and last_obstacle.position.x < camera.position.x + randi_range(MIN_OBSTACLE_DISTANCE, MAX_OBSTACLE_DISTANCE)):
		var obs_type = obstacles_types[randi() % obstacles_types.size()]
		var obs
		var max_obs = difficulty + 1
		
		for i in range(randi() % max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node('Sprite2D').texture.get_height()
			var obs_scale = obs.get_node('Sprite2D').scale
			
			var obs_x = camera.position.x + screen_size.x / 2.0 + (i * 15)
			var obs_y = ground_top_y - (obs_height * obs_scale.y / 2) + 3
			
			last_obstacle = obs
			add_obs(obs, obs_x, obs_y)
			
		if difficulty == MAX_DIFFICULTY:
			if randi() % 2 == 0:
				obs = bird_scene.instantiate()
				var obs_x = camera.position.x + screen_size.x / 2.0 + 100
				var obs_y = bird_heights[randi() % bird_heights.size()]
				add_obs(obs, obs_x, obs_y)

func add_obs(obs, x: float, y: float) -> void:
	obs.position = Vector2(x, y)
	obs.body_entered.connect(_on_obstacle_hit)
	parent_node.add_child(obs)
	obstacles.append(obs)

func _on_obstacle_hit(body) -> void:
	if body.name == player.name:
		Signals.emit_signal("take_damage")

func cleanup_obstacles() -> void:
	if not camera:
		return
		
	var camera_left_edge = camera.position.x - screen_size.x / 2.0
	for i in range(obstacles.size() - 1, -1, -1):
		var obs = obstacles[i]
		if obs.position.x < camera_left_edge - 100:
			obstacles.remove_at(i)
			obs.queue_free()
