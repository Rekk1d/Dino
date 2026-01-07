extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var camera_2D: Camera2D = $Camera2D
@onready var ground: TileMapLayer = $Ground
@onready var hud: CanvasLayer = $HUD

const PLAYER_START_POSITION := Vector2i(25, 183)
const CAMERA_START_POSITION := Vector2i(192, 108)
const START_SPEED: float = 1.0
const MAX_SPEED: float = 3.0
const SPEED_MODIFIER: int = 5000
const SPAWN_DISTANCE: float = 300.0 
const MAX_SEGMENTS: int = 5
const SCORE_MODIFIER: int = 10

var screen_size: Vector2i
var speed: float

var score: int
var is_game_running = false

var ground_segments: Array[TileMapLayer] = []
var segment_width: float = 0  
var next_spawn_x: float = 0 


func _ready() -> void:
	screen_size = get_window().size
	
	var used_rect = ground.get_used_rect()
	var tile_set = ground.tile_set
	var tile_size = tile_set.tile_size
	segment_width = used_rect.size.x * tile_size.x
	
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
		player.position.x += speed
		camera_2D.position.x += speed
		
		score += int(speed)
		show_score()
		
		check_and_spawn_ground()
		cleanup_old_segments()
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
