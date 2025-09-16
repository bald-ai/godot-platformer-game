extends Area2D

enum ShotColor { GREEN, PURPLE }

@export var color: int = ShotColor.GREEN
@export var velocity: Vector2
@export var world_mask: int = 1 << 7
@export var portal_manager_path: NodePath

var _last_pos: Vector2
var _active := true
var _mgr: Node = null

func _ready() -> void:
	_last_pos = global_position
	if _mgr == null:
		if portal_manager_path != NodePath():
			_mgr = get_node_or_null(portal_manager_path)
		if _mgr == null:
			var scene := get_tree().current_scene
			if scene:
				_mgr = scene.get_node_or_null("PortalPair")

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
		if color == ShotColor.GREEN:
			print("Green hit at ", hit.position)
			if _mgr and _mgr.has_method("spawn_portal_f"):
				_mgr.spawn_portal_f(hit.position)
		else:
			print("Purple hit at ", hit.position)
			if _mgr and _mgr.has_method("spawn_portal_g"):
				_mgr.spawn_portal_g(hit.position)
		queue_free()
		return

	global_position = to
	_last_pos = global_position
