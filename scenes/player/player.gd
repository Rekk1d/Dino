extends CharacterBody2D
@onready var animationPlayer: AnimatedSprite2D = $AnimatedSprite2D
@onready var run_collision: CollisionShape2D = $RunCollision
@onready var duck_collision: CollisionShape2D = $DuckCollision

enum {
	IDLE,
	RUN,
	JUMP,
	DUCK
}

const GRAVITY: int = 4200
const JUMP_SPEED: int = -1000

var state = RUN

func _physics_process(delta: float) -> void:
	match state:
		IDLE: idle_state()
		RUN: run_state()
		JUMP: jump_state()
		DUCK: duck_state()
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		
	move_and_slide()

func idle_state() -> void:
	animationPlayer.play("Idle")
	
	if Input.is_action_pressed("Duck"):
		state = DUCK
	
func run_state() -> void:
	animationPlayer.play("Run")
	duck_collision.disabled = true
	
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		state = JUMP
		velocity.y = JUMP_SPEED
	
	if Input.is_action_pressed("Duck"):
		state = DUCK
	
func jump_state() -> void:
	animationPlayer.play("Jump")
	if is_on_floor():
		state = RUN

func duck_state() -> void:
	animationPlayer.play("Duck")
	duck_collision.disabled = false
	run_collision.disabled = true
	if Input.is_action_just_released("Duck"):
		state = RUN
		duck_collision.disabled = true
		run_collision.disabled = false
