extends RigidBody2D

@export var speed: float = 300.0
@export var direction: Vector2 = Vector2.RIGHT
@export var world_mask: int = 1 << 0
@export var max_lifetime_seconds: float = 6.0

var _age_seconds: float = 0.0

func _ready() -> void:
	gravity_scale = 0.0
	freeze = false
	# Enable continuous collision detection and contact monitoring so collisions are reliable at any time scale
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	max_contacts_reported = 1
	collision_mask = world_mask

	rotation = direction.angle()
	linear_velocity = direction.normalized() * speed
	add_to_group("EnemyBullet")
	print("Bullet: ready at ", global_position, " dir=", direction, " speed=", speed, " mask=", world_mask)

	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_age_seconds += delta
	if _age_seconds >= max_lifetime_seconds:
		queue_free()
		return

func _on_body_entered(body: Node) -> void:
	queue_free()
