extends RigidBody2D

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var fire_interval_seconds: float = 2.0
@export var bullet_speed: float = 250.0
@export var shoot_right: bool = true

@onready var muzzle: Marker2D = $Marker2D
@onready var timer: Timer = $Timer
@onready var anim: AnimatedSprite2D = $AnimatedSpriteShoot

func _ready() -> void:
	freeze = true
	if timer:
		timer.wait_time = fire_interval_seconds
		timer.autostart = true
		timer.timeout.connect(_on_timer_timeout)
		print("Turret: timer start (", fire_interval_seconds, "s)")
		timer.start()

func _on_timer_timeout() -> void:
	if anim:
		anim.play("shoot")
		anim.animation_finished.connect(_on_anim_finished, CONNECT_ONE_SHOT)
	print("Turret: shoot")
	_spawn_bullet()

func _spawn_bullet() -> void:
	if bullet_scene == null:
		return
	var b := bullet_scene.instantiate() as RigidBody2D
	if b == null:
		return
	# Spawn at the muzzle and orient based on the muzzle's transform.
	b.global_position = muzzle.global_position if muzzle else global_position
	var dir := (muzzle.global_transform.x.normalized()) if muzzle else (Vector2.RIGHT if shoot_right else Vector2.LEFT)
	b.set("direction", dir)
	b.set("speed", bullet_speed)
	# Avoid instant self-collision by adding an explicit collision exception
	b.add_collision_exception_with(self)
	print("Turret: spawn bullet at ", b.global_position, " dir=", dir)
	get_tree().current_scene.add_child(b)

func _on_anim_finished() -> void:
	if anim:
		anim.play("idle")
