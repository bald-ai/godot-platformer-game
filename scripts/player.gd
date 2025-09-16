extends CharacterBody2D

const BULLET_SCENE: PackedScene = preload("res://scenes/shot.tscn")
@export var portal_pair_scene: PackedScene = preload("res://scenes/portal_pair.tscn")
@export var bullet_speed: float = 1000.0

var speed: float = 100.0
const JUMP_VELOCITY: float = -300.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var facing_dir: int = 1
var _portal_mgr: Node = null

func _ready() -> void:
	_portal_mgr = _get_or_spawn_portal_pair()

func _physics_process(delta: float) -> void:
	if not is_on_floor(): velocity += get_gravity() * delta
	speed = 175 if Input.is_action_pressed("sprint") else 100
	if Input.is_action_just_pressed("ui_accept") and is_on_floor(): velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("move_left", "move_right")
	if direction > 0:
		animated_sprite_2d.flip_h = false; facing_dir = 1
	elif direction < 0:
		animated_sprite_2d.flip_h = true; facing_dir = -1

	if is_on_floor():
		if direction == 0: animated_sprite_2d.play("idle")
		else: animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("jump")

	if direction: velocity.x = direction * speed
	else: velocity.x = move_toward(velocity.x, 0, speed)
	move_and_slide()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("shoot_first_portal"):  # F -> GREEN
		_shoot(0)
	if Input.is_action_just_pressed("shoot_second_portal"): # G -> PURPLE
		_shoot(1)

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
