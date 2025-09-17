extends CharacterBody2D

const BULLET_SCENE: PackedScene = preload("res://scenes/shot.tscn")
@export var portal_pair_scene: PackedScene = preload("res://scenes/portal.tscn")
@export var bullet_speed: float = 300.0

var speed: float = 100.0
const JUMP_VELOCITY: float = -300.0
const PARRY_DURATION: float = 0.33
const DASH_SPEED: float = 333.33
const DASH_DURATION: float = 0.09

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var facing_dir: int = 1
var _portal_mgr: Node = null
var _parry_time_left: float = 0.0
var _is_dashing: bool = false
var _dash_time_left: float = 0.0
var _dash_dir: int = 1

func _ready() -> void:
	_portal_mgr = _get_or_spawn_portal_pair()

func _physics_process(delta: float) -> void:
	if not _is_dashing and not is_on_floor(): velocity += get_gravity() * delta
	speed = 175 if Input.is_action_pressed("sprint") else 100
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not _is_dashing: velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("move_left", "move_right")

	# Handle dash input (F mapped to action "dash")
	if Input.is_action_just_pressed("dash") and not _is_dashing:
		var dir_int := 1 if direction > 0 else (-1 if direction < 0 else facing_dir)
		_begin_dash(dir_int)

	# Update facing only if not currently dashing
	if not _is_dashing:
		if direction > 0:
			animated_sprite_2d.flip_h = false; facing_dir = 1
		elif direction < 0:
			animated_sprite_2d.flip_h = true; facing_dir = -1

	# Animation state
	if _is_dashing:
		animated_sprite_2d.play("dash")
	else:
		if is_on_floor():
			if direction == 0: animated_sprite_2d.play("idle")
			else: animated_sprite_2d.play("run")
		else:
			animated_sprite_2d.play("jump")

	# Movement
	if _is_dashing:
		# Maintain horizontal dash velocity; gravity disabled while dashing
		velocity.x = DASH_SPEED * _dash_dir
		velocity.y = 0.0
	else:
		if direction: velocity.x = direction * speed
		else: velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

	# End dash on collision or when duration elapses
	if _is_dashing:
		_dash_time_left -= delta
		var collided := get_slide_collision_count() > 0
		if collided or _dash_time_left <= 0.0:
			_is_dashing = false
			if collided:
				velocity.x = 0.0

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("shoot_first_portal"):  # F -> GREEN
		_shoot(0)
	if Input.is_action_just_pressed("shoot_second_portal"): # G -> PURPLE
		_shoot(1)

	if Input.is_action_just_pressed("parry"):
		_parry_time_left = PARRY_DURATION
	if _parry_time_left > 0.0:
		_parry_time_left -= delta

func _shoot(color_id: int) -> void:
	var b := BULLET_SCENE.instantiate() as Area2D
	if b == null:
		push_warning("Could not instantiate shot.tscn"); return

	var spawn_offset := Vector2(16.0 * facing_dir, -2.0)
	b.global_position = global_position + spawn_offset

	var dir := Vector2(facing_dir, 0.0)
	b.set("velocity", dir * bullet_speed)
	b.set("color", color_id)
	if _portal_mgr:
		b.set("portal_manager_path", _portal_mgr.get_path())
		b.set("_mgr", _portal_mgr)

	var spr := b.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr: spr.flip_h = (facing_dir == -1)

	get_tree().current_scene.add_child(b)

func _get_or_spawn_portal_pair() -> Node:
	var n := get_tree().current_scene.get_node_or_null("PortalPair")
	if n:
		return n
	if portal_pair_scene:
		var inst := portal_pair_scene.instantiate()
		get_tree().current_scene.add_child(inst)
		return inst
	return null

func is_parrying_active() -> bool:
	return _parry_time_left > 0.0

func _begin_dash(dir: int) -> void:
	_is_dashing = true
	_dash_time_left = DASH_DURATION
	_dash_dir = dir
	facing_dir = dir
	animated_sprite_2d.flip_h = (dir == -1)
	velocity.x = DASH_SPEED * dir
	velocity.y = 0.0
	animated_sprite_2d.play("dash")
