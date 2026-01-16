extends CharacterBody2D

signal died
signal health_changed(current_health: int)

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
const SHIELD_TIMER: int = 10

var current_state: State = State.IDLE
var health: int
var max_health: int = 3
var has_shield: bool = false

func _ready() -> void:
	Signals.connect("take_damage", Callable(self, "_on_take_damage"))
	Signals.connect("health_recover", Callable(self, "_on_health_recover"))
	Signals.connect("get_shield", Callable(self, "_on_get_shield"))
	health = max_health
	health_changed.emit(health)
	
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
	if has_shield:
		has_shield = false
		animation_player.modulate = Color(1, 1, 1, 1) 
		health_changed.emit(health)
	elif health > 1:
		health -= 1
		health_changed.emit(health)
	else:
		health_changed.emit(0)
		died.emit()
		
func _on_health_recover() -> void:
	if health != max_health:
		health += 1
		health_changed.emit(health)
		
func _on_get_shield() -> void:
	has_shield = true
	animation_player.modulate = Color(0.5, 0.8, 1, 1) 
	await get_tree().create_timer(SHIELD_TIMER).timeout
	has_shield = false
	animation_player.modulate = Color(1, 1, 1, 1) 
		
func reset() -> void:
	health = max_health
	health_changed.emit(health)
	change_state(State.IDLE)
