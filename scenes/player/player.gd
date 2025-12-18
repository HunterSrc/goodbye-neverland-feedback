extends CharacterBody2D

# --- FEEDBACK METER ---
@export var feedback_max := 100.0
@export var feedback_per_hit := 15.0
@export var feedback_decay := 10.0  # al secondo
var feedback := 0.0


# --- MOVIMENTO ---
@export var speed := 220.0
@export var jump_force := -420.0
@export var gravity := 1200.0
@export var coyote_time := 0.1
var coyote_timer := 0.0

# --- DASH ---
@export var dash_speed := 600.0
@export var dash_duration := 0.01
@export var dash_cooldown := 0.3
var is_dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0

# --- ATTACCO ---
@export var attack_duration := 0.08
var is_attacking := false

# --- RITMO / MUSICA ---
@export var beat_interval := 0.4  # durata di un beat
@export var rhythm_window := 0.08 # tolleranza
var beat_timer := 0.0

func _ready():
	$AttackHitbox.monitoring = false

func _physics_process(delta):
	# --- GRAVITÀ ---
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		coyote_timer = coyote_time
	
	# --- COYOTE TIME ---
	if not is_on_floor():
		coyote_timer -= delta

	# --- JUMP ---
	if Input.is_action_just_pressed("jump") and coyote_timer > 0:
		velocity.y = jump_force
		coyote_timer = 0

	# --- DASH COOLDOWN ---
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# --- DASH ---
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		var dir = Input.get_axis("move_left", "move_right")
		if dir == 0:
			dir = 1
		velocity.x = dir * dash_speed

	if is_dashing:
		dash_timer -= delta
		velocity.y = 0
		if dash_timer <= 0:
			is_dashing = false
	else:
		# --- MOVIMENTO ORIZZONTALE ---
		var direction := Input.get_axis("move_left", "move_right")
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * speed, speed * delta * 6)
		else:
			velocity.x = move_toward(velocity.x, 0, speed * delta * 6)

	# --- ATTACCO ---
	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		$AttackHitbox.monitoring = true
		
		if is_on_beat():
			feedback += feedback_per_hit
			if feedback > feedback_max:
				feedback = feedback_max
			print("HIT A TEMPO! Feedback:", feedback)
		else:
			print("FUORI TEMPO")
		
		await get_tree().create_timer(attack_duration).timeout
		$AttackHitbox.monitoring = false
		is_attacking = false

	# decay feedback
	feedback -= feedback_decay * delta
	if feedback < 0:
		feedback = 0


	# --- MOVIMENTO FINALE ---
	move_and_slide()

	# --- TIMER BEAT ---
	beat_timer += delta
	if beat_timer >= beat_interval:
		beat_timer = 0

# --- FUNZIONE RITMO ---
func is_on_beat() -> bool:
	return beat_timer <= rhythm_window or beat_timer >= beat_interval - rhythm_window
