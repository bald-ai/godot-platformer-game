extends Node2D

@onready var portal_a: Area2D = $PortalA
@onready var portal_a_anim: AnimatedSprite2D = $PortalA/AnimatedSprite2D
@onready var portal_a_shape: CollisionShape2D = $PortalA/CollisionShape2D
@onready var portal_a_dest: Marker2D = $PortalA/Destination

@onready var portal_b: Area2D = $PortalB
@onready var portal_b_anim: AnimatedSprite2D = $PortalB/AnimatedSprite2D
@onready var portal_b_shape: CollisionShape2D = $PortalB/CollisionShape2D
@onready var portal_b_dest: Marker2D = $PortalB/Destination

var a_active: bool = false
var b_active: bool = false

func _ready() -> void:
	# Start with both portals inactive and non-interactive
	if portal_a:
		portal_a.visible = false
	if portal_a_shape:
		portal_a_shape.disabled = true
	if portal_b:
		portal_b.visible = false
	if portal_b_shape:
		portal_b_shape.disabled = true

	# Connect body_entered for teleport gating
	if portal_a and not portal_a.body_entered.is_connected(_on_portal_a_body_entered):
		portal_a.body_entered.connect(_on_portal_a_body_entered)
	if portal_b and not portal_b.body_entered.is_connected(_on_portal_b_body_entered):
		portal_b.body_entered.connect(_on_portal_b_body_entered)

func spawn_portal_f(pos: Vector2) -> void:
	if not is_node_ready():
		await ready
	if portal_a == null:
		portal_a = get_node_or_null("PortalA") as Area2D
	if portal_a_anim == null:
		portal_a_anim = get_node_or_null("PortalA/AnimatedSprite2D") as AnimatedSprite2D
	if portal_a_shape == null:
		portal_a_shape = get_node_or_null("PortalA/CollisionShape2D") as CollisionShape2D

	if portal_a:
		portal_a.global_position = pos
		portal_a.visible = true
		if portal_a_shape:
			portal_a_shape.disabled = false
		if portal_a_anim:
			portal_a_anim.play("idle")
		a_active = true
	print("Portal spawned F at ", pos)

func spawn_portal_g(pos: Vector2) -> void:
	if not is_node_ready():
		await ready
	if portal_b == null:
		portal_b = get_node_or_null("PortalB") as Area2D
	if portal_b_anim == null:
		portal_b_anim = get_node_or_null("PortalB/AnimatedSprite2D") as AnimatedSprite2D
	if portal_b_shape == null:
		portal_b_shape = get_node_or_null("PortalB/CollisionShape2D") as CollisionShape2D

	if portal_b:
		portal_b.global_position = pos
		portal_b.visible = true
		if portal_b_shape:
			portal_b_shape.disabled = false
		if portal_b_anim:
			portal_b_anim.play("idle")
		b_active = true
	print("Portal spawned G at ", pos)

func is_a_active() -> bool:
	return a_active

func is_b_active() -> bool:
	return b_active

func _on_portal_a_body_entered(body: Node2D) -> void:
	if not a_active or not b_active:
		return
	if body == null or not body.is_in_group("Player"):
		return
	if portal_b_dest:
		body.global_position = portal_b_dest.global_position

func _on_portal_b_body_entered(body: Node2D) -> void:
	if not a_active or not b_active:
		return
	if body == null or not body.is_in_group("Player"):
		return
	if portal_a_dest:
		body.global_position = portal_a_dest.global_position
