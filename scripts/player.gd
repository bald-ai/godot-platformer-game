extends CharacterBody2D

# Change the path to where you saved GreenShot.tscn
const BULLET_SCENE: PackedScene = preload("res://scenes/shot.tscn")

var speed: float = 100.0
const JUMP_VELOCITY: float = -300.0
@export var bullet_speed: float = 100.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var facing_dir: int = 1  # 1 = right, -1 = left

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	speed = 175 if Input.is_action_pressed("sprint") else 100

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("move_left", "move_right")

	if direction > 0:
		animated_sprite_2d.flip_h = false
		facing_dir = 1
	elif direction < 0:
		animated_sprite_2d.flip_h = true
		facing_dir = -1

	if is_on_floor():
		if direction == 0:
			animated_sprite_2d.play("idle")
		else:
			animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("jump")

	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("shoot_first_portal"):
		shoot()

func shoot() -> void:
	var b := BULLET_SCENE.instantiate() as Area2D
	var dir := Vector2(facing_dir, 0.0)

	# spawn a bit in front; tweak Y if needed
	var spawn_offset := Vector2(16.0 * facing_dir, -2.0)
	b.global_position = global_position + spawn_offset

	# do NOT rotate the bullet root (prevents the Y drift)
	b.rotation = 0.0
	b.velocity = dir * bullet_speed

	# visual only: flip the sprite for left/right
	var spr := b.get_node("AnimatedSprite2D") as AnimatedSprite2D
	spr.flip_h = (facing_dir == -1)

	get_tree().current_scene.add_child(b)
