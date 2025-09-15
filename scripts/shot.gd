extends Area2D

@export var velocity: Vector2
@export var world_mask: int = 1 << 7

var _last_pos: Vector2
var _active := true

func _ready() -> void:
	_last_pos = global_position
	$AnimatedSprite2D.play("green_flight")

func _physics_process(delta: float) -> void:
	if not _active:
		return

	var from := _last_pos
	var to := global_position + velocity * delta

	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(from, to)
	q.collision_mask = world_mask
	q.hit_from_inside = true

	var hit := space.intersect_ray(q)
	if hit:
		_active = false
		velocity = Vector2.ZERO

		_place_portal_a(hit.position, hit.normal)

		$AnimatedSprite2D.play("green_impact")
		await $AnimatedSprite2D.animation_finished
		queue_free()
		return

	global_position = to
	_last_pos = global_position

func _place_portal_a(pos: Vector2, normal: Vector2) -> void:
	var portal_a := get_tree().current_scene.get_node_or_null("PortalPair/PortalA") as Node2D
	if portal_a == null:
		push_warning("PortalPair/PortalA not found in the scene tree")
		return

	# Nudge off the surface to avoid z-fighting/overlap
	portal_a.global_position = pos + normal * 2.0

	# Rotate to face outward; tweak +PI/2 if your sprite faces a different axis
	portal_a.rotation = normal.angle()

	portal_a.visible = true
	var shape := portal_a.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.disabled = false
