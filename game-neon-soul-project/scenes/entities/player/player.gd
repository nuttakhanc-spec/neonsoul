extends CharacterBody2D

#bar
signal update_hp_bar(hp_bar_value: int)

enum State {
	IDLE,
	RUN,
	ATTACK,
	DEAD
}

const DASH_SPEED = 2000 # ความเร็วตอนพุ่ง (เอาให้แรงกว่าเดินปกติ 5-6 เท่า)
const DASH_DURATION = 0.15 # ระยะเวลาพุ่ง (แค่ 0.1 - 0.2 วินาทีพอครับ)
@onready var dash = $Dash # ต้องมี Node Dash อยู่ใน Player นะ

@export_category("stats")
@export var speed: int = 400
@export var attack_speed: float = 0.6
@export var attack_damage: int = 60

var state: State = State.IDLE
var move_direction: Vector2 = Vector2(0,0)
# เพิ่มตัวแปรนี้ด้านบน ใต้ var move_direction
var dash_direction: Vector2 = Vector2.ZERO
var can_dash: bool = true
# bar
var hitpoints_max: int

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]



func _ready() -> void:
	#bar
	
	animation_tree.set_active(true)



func _physics_process(_delta: float) -> void:
	print("state: ", state, " | is_dashing: ", dash.is_dashing())
	if not state == State.ATTACK:
		movement_loop()
	
func movement_loop() -> void:
	move_direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	move_direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))

	if dash.is_dashing():
		velocity = dash_direction.normalized() * DASH_SPEED
		move_and_slide()
		return

	dash_direction = Vector2.ZERO
	velocity = move_direction.normalized() * speed
	move_and_slide()

	if state == State.IDLE or state == State.RUN:
		if move_direction.x < -0.01:
			$Sprite2D.flip_h = true
		elif move_direction.x > 0.01:
			$Sprite2D.flip_h = false

	if velocity != Vector2.ZERO and state == State.IDLE:
		state = State.RUN
		update_animation()
	elif velocity == Vector2.ZERO and state == State.RUN:
		state = State.IDLE
		update_animation()
		

		
func update_animation() -> void:
	match state:
		State.IDLE:
			animation_playback.travel("idle")
		State.RUN:
			animation_playback.travel("run")
		State.ATTACK:
			animation_playback.travel("attack")
			

			
func attack() -> void:
	if state == State.ATTACK:
		return
	state = State.ATTACK
	
	var mouse_pos: Vector2 = get_global_mouse_position()
	var attack_dir: Vector2 = (mouse_pos - global_position).normalized()
	$Sprite2D.flip_h = attack_dir.x < 0 and abs(attack_dir.x) >= abs(attack_dir.y)
	animation_tree.set("parameters/attack/BlendSpace2D/blend_position", attack_dir)
	update_animation()
	
	await get_tree().create_timer(attack_speed).timeout
	state = State.IDLE
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		attack()
	if Input.is_action_just_pressed("dash") and can_dash and not dash.is_dashing():
		# ล็อกทิศตอนกด ถ้าไม่ได้กดทิศไหน ใช้ทิศที่หันอยู่
		dash_direction = move_direction if move_direction != Vector2.ZERO \
			else Vector2(1 if not $Sprite2D.flip_h else -1, 0)
		dash.start_dash(DASH_DURATION)
		_dash_cooldown()

func _dash_cooldown() -> void:
	can_dash = false
	await get_tree().create_timer(0.5).timeout
	can_dash = true
		
func death() -> void:
	print("i died")
		
	


func _on_hitbox_area_entered(area: Area2D) -> void:
	area.owner.take_damage(attack_damage)
