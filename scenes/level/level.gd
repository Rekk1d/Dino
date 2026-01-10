extends Node2D

# Obstacles
var box_scene = preload("res://scenes/obstacles/box.tscn")
#var crabby_scene = preload("res://scenes/obstacles/crabby.tscn")
var barrel_scene = preload("res://scenes/obstacles/barrel.tscn")
var bird_scene = preload("res://scenes/obstacles/bird.tscn")
var obstacles_types := [box_scene, barrel_scene]
var obstacles: Array
var bird_heights = [125, 170]
@onready var player: CharacterBody2D = $Player
@onready var camera_2D: Camera2D = $Camera2D
@onready var ground: TileMapLayer = $Ground
@onready var hud: CanvasLayer = $HUD

# Game constants
const PLAYER_START_POSITION := Vector2i(25, 183)
const CAMERA_START_POSITION := Vector2i(192, 108)
const START_SPEED: float = 1.0
const MAX_SPEED: float = 3.0
const SPEED_MODIFIER: int = 5000
const SPAWN_DISTANCE: float = 300.0 
const MAX_SEGMENTS: int = 5
const SCORE_MODIFIER: int = 10
const MIN_OBSTACLE_DISTANCE: int = 200
const MAX_OBSTACLE_DISTANCE: int = 500
const MAX_DIFFICULTY: int = 2

# Game variables
var screen_size: Vector2i
var speed: float
var score: int
var is_game_running = false
var ground_segments: Array[TileMapLayer] = []
var segment_width: float = 0  
var next_spawn_x: float = 0 
var last_obstacle
var ground_top_y
var difficulty

func _ready() -> void:
	screen_size = get_window().size
	
	var used_rect = ground.get_used_rect()
	var tile_set = ground.tile_set
	var tile_size = tile_set.tile_size
	segment_width = used_rect.size.x * tile_size.x
	ground_top_y = ground.position.y + used_rect.position.y * tile_size.y
	ground_segments.append(ground)
	next_spawn_x = segment_width
	new_game()

func new_game() -> void:
	player.position = PLAYER_START_POSITION
	player.velocity = Vector2i(0, 0)
	camera_2D.position = CAMERA_START_POSITION
	
	for i in range(ground_segments.size() - 1, 0, -1):
		ground_segments[i].queue_free()
		ground_segments.remove_at(i)
	
	ground.position = Vector2i(0, 0)
	next_spawn_x = segment_width
	score = 0
	show_score()
	hud.get_node("Start").show()

func _process(_delta: float) -> void:
	if is_game_running:
		speed = START_SPEED + float(score) / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED
		change_difficulty()
		
		generate_obstacles()
		player.position.x += speed
		camera_2D.position.x += speed
		
		score += int(speed)
		show_score()
		
		check_and_spawn_ground()
		cleanup_old_segments()
		cleanup_obstacles()
	else:
		if Input.is_action_just_pressed("ui_accept"):
			is_game_running = true
			hud.get_node("Start").hide()

func check_and_spawn_ground() -> void:
	if camera_2D.position.x > next_spawn_x - SPAWN_DISTANCE:
		if ground_segments.size() < MAX_SEGMENTS:
			spawn_ground_segment()

func spawn_ground_segment() -> void:
	var new_segment = ground.duplicate()
	
	new_segment.position.x = next_spawn_x
	new_segment.position.y = ground.position.y
	
	add_child(new_segment)
	
	ground_segments.append(new_segment)
	
	next_spawn_x += segment_width

func cleanup_old_segments() -> void:
	var camera_left_edge = camera_2D.position.x - screen_size.x / 2.0
	
	for i in range(ground_segments.size() - 1, 0, -1):
		var segment = ground_segments[i]
		var segment_right_edge = segment.position.x + segment_width
		
		if segment_right_edge < camera_left_edge:
			ground_segments.remove_at(i)
			segment.queue_free()
			
func show_score() -> void:
	hud.get_node("Score").text = "SCORE: " + str(score / SCORE_MODIFIER)
	 
func generate_obstacles() -> void:
	if obstacles.is_empty() or (last_obstacle != null and last_obstacle.position.x < camera_2D.position.x + randi_range(MIN_OBSTACLE_DISTANCE, MAX_OBSTACLE_DISTANCE)):
		var obs_type = obstacles_types[randi() % obstacles_types.size()]
		var obs
		var max_obs = difficulty + 1
		for i in range(randi() % max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node('Sprite2D').texture.get_height()
			var obs_scale = obs.get_node('Sprite2D').scale
			
			var obs_x = camera_2D.position.x + screen_size.x / 2.0  + (i * 15)
			var obs_y = ground_top_y - (obs_height * obs_scale.y / 2) + 3
			
			last_obstacle = obs
			add_obs(obs, obs_x, obs_y)
			
		if difficulty == MAX_DIFFICULTY:
			if(randi() % 2 == 0):
				obs = bird_scene.instantiate()
				var obs_x = camera_2D.position.x + screen_size.x / 2.0 + 100
				var obs_y = bird_heights[randi() % bird_heights.size()]
				add_obs(obs, obs_x, obs_y)
		
func add_obs(obs, x, y) -> void:
	obs.position = Vector2(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacles.append(obs)
	
func hit_obs(body):
	if body.name == player.name:
		print('hit')
		
func cleanup_obstacles() -> void:
	var camera_left_edge = camera_2D.position.x - screen_size.x / 2.0
	for i in range(obstacles.size() - 1, -1, -1):
		var obs = obstacles[i]
		if obs.position.x < camera_left_edge - 100:
			obstacles.remove_at(i)
			obs.queue_free()
	
func change_difficulty() -> void:
	difficulty = score / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY
