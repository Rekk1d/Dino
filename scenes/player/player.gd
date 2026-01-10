extends CharacterBody2D

signal died

@onready var animation_player: AnimatedSprite2D = $AnimatedSprite2D
@onready var run_collision: CollisionShape2D = $RunCollision
@onready var duck_collision: CollisionShape2D = $DuckCollision

enum State {
	IDLE,
	RUN,
	JUMP,
	DUCK
}

const GRAVITY: int = 4200
const JUMP_SPEED: int = -900

var current_state: State = State.IDLE
var health: int
var max_health: int  = 3

func _ready() -> void:
	Signals.connect("take_damage", Callable(self, "_on_take_damage"))
	health = max_health
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	process_state()
	
	move_and_slide()

func process_state() -> void:
	match current_state:
		State.IDLE:
			process_idle()
		State.RUN:
			process_run()
		State.JUMP:
			process_jump()
		State.DUCK:
			process_duck()

func process_idle() -> void:
	animation_player.play("Idle")
	
	if Input.is_action_pressed("Duck"):
		change_state(State.DUCK)
	if Input.is_action_just_pressed("ui_accept"):
		change_state(State.RUN)

func process_run() -> void:
	animation_player.play("Run")
	
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_SPEED
		change_state(State.JUMP)
	elif Input.is_action_pressed("Duck"):
		change_state(State.DUCK)

func process_jump() -> void:
	animation_player.play("Jump")
	
	if is_on_floor():
		change_state(State.RUN)

func process_duck() -> void:
	animation_player.play("Duck")
	
	if Input.is_action_just_released("Duck"):
		change_state(State.RUN)

func change_state(new_state: State) -> void:
	exit_state(current_state)

	current_state = new_state
	
	enter_state(new_state)

func exit_state(state: State) -> void:
	match state:
		State.DUCK:
			duck_collision.disabled = true
			run_collision.disabled = false

func enter_state(state: State) -> void:
	match state:
		State.DUCK:
			duck_collision.disabled = false
			run_collision.disabled = true
			
func _on_take_damage() -> void:
	print('damage')
	if health > 1:
		health -= 1
	else:
		died.emit()
		change_state(State.IDLE)
