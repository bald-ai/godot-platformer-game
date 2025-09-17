extends Node2D

@export var portal_green_path: NodePath
@export var portal_purple_path: NodePath
@export var destination_offset: float = 13.0
@export var player_group: StringName = "Player"
@export var player_layer_mask: int = 1 << 1
@export var teleport_cooldown_sec: float = 0.5

var _green_active: bool = false
var _purple_active: bool = false

# Tracks which surface face currently holds which portal (by key)
var _face_to_color: Dictionary = {}
var _color_to_face: Dictionary = {}

# Tracks per-body cooldown end times to avoid instant re-entry ping-pong
var _cooldown_until_by_body: Dictionary = {}

var _portal_green: Area2D
var _portal_purple: Area2D

func _ready() -> void:
	_bind_portals()
	# Start disabled/hidden; they become active when shots hit
	_deactivate_portal(_portal_green)
	_deactivate_portal(_portal_purple)

	# Connect teleport events
	if _portal_green and not _portal_green.body_entered.is_connected(_on_green_body_entered):
		_portal_green.body_entered.connect(_on_green_body_entered)
	if _portal_purple and not _portal_purple.body_entered.is_connected(_on_purple_body_entered):
		_portal_purple.body_entered.connect(_on_purple_body_entered)

func _bind_portals() -> void:
	# Prefer explicit paths if provided
	if portal_green_path != NodePath():
		_portal_green = get_node_or_null(portal_green_path) as Area2D
	if portal_purple_path != NodePath():
		_portal_purple = get_node_or_null(portal_purple_path) as Area2D

	# Common fallback names
	if _portal_green == null:
		_portal_green = _find_portal_by_names(["PortalGreen", "PortalA", "Portal1"]) as Area2D
	if _portal_purple == null:
		_portal_purple = _find_portal_by_names(["PortalPurple", "PortalB", "Portal2"]) as Area2D

	_configure_portal_collision(_portal_green)
	_configure_portal_collision(_portal_purple)

func _configure_portal_collision(p: Area2D) -> void:
	if p == null:
		return
	# Ensure areas detect the player's physics layer
	p.collision_mask = p.collision_mask | player_layer_mask

func _find_portal_by_names(names: Array[String]) -> Node:
	for n in names:
		var child := get_node_or_null(n)
		if child is Area2D:
			return child
	var root := get_tree().current_scene
	if root:
		for n in names:
			var any := root.find_child(n, true, false)
			if any is Area2D:
				return any
	return null

func _deactivate_portal(p: Area2D) -> void:
	if p == null:
		return
	p.visible = false
	var shape := p.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.disabled = true

func _activate_portal(p: Area2D) -> void:
	if p == null:
		return
	p.visible = true
	var shape := p.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.disabled = false

func _clear_mapping_for_color(color: String) -> void:
	var old_face: String = _color_to_face.get(color, "")
	if old_face != "":
		_face_to_color.erase(old_face)
	_color_to_face.erase(color)

func _set_destination_by_normal(p: Area2D, normal: Vector2) -> void:
	if p == null:
		return
	var dest := p.get_node_or_null("Destination") as Marker2D
	if dest == null:
		return
	var n := normal
	if n == Vector2.ZERO:
		n = Vector2.RIGHT
	if abs(n.x) >= abs(n.y):
		dest.position = Vector2(destination_offset * sign(n.x), 0.0)
	else:
		dest.position = Vector2(0.0, destination_offset * sign(n.y))

func _play_color_idle(p: Area2D, color: String) -> void:
	if p == null:
		return
	var spr := p.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr:
		var idle := "%s_idle" % color
		if spr.sprite_frames and spr.sprite_frames.has_animation(idle):
			spr.play(idle)

func _play_color_create(p: Area2D, color: String) -> void:
	if p == null:
		return
	var spr := p.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr and spr.sprite_frames:
		var create := "%s_create" % color
		var idle := "%s_idle" % color
		if spr.sprite_frames.has_animation(create):
			spr.play(create)
			if not spr.animation_finished.is_connected(Callable(self, "_on_create_finished")):
				spr.animation_finished.connect(Callable(self, "_on_create_finished").bind(spr, idle), Object.CONNECT_ONE_SHOT)
			return
	# Fallback: no create animation, just idle
	_play_color_idle(p, color)

func _play_color_destroy(p: Area2D, color: String) -> void:
	if p == null:
		return
	var spr := p.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr and spr.sprite_frames:
		var destroy := "%s_destroy" % color
		if spr.sprite_frames.has_animation(destroy):
			spr.play(destroy)
			if not spr.animation_finished.is_connected(Callable(self, "_on_destroy_finished")):
				spr.animation_finished.connect(Callable(self, "_on_destroy_finished").bind(p), Object.CONNECT_ONE_SHOT)
			return
	# Fallback: immediately hide/disable
	_deactivate_portal(p)

func _on_create_finished(spr: AnimatedSprite2D, idle_anim: String) -> void:
	if spr and is_instance_valid(spr) and spr.sprite_frames and spr.sprite_frames.has_animation(idle_anim):
		spr.play(idle_anim)

func _on_destroy_finished(portal: Area2D) -> void:
	if portal:
		_deactivate_portal(portal)

func _spawn_destroy_ghost(from_portal: Area2D, color: String) -> void:
	if from_portal == null:
		return
	var spr_src := from_portal.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr_src == null or spr_src.sprite_frames == null:
		return
	var destroy_anim := "%s_destroy" % color
	if not spr_src.sprite_frames.has_animation(destroy_anim):
		return
	var ghost := AnimatedSprite2D.new()
	ghost.sprite_frames = spr_src.sprite_frames
	ghost.global_position = from_portal.global_position
	ghost.z_index = spr_src.z_index
	add_child(ghost)
	ghost.play(destroy_anim)
	ghost.animation_finished.connect(Callable(ghost, "queue_free"), Object.CONNECT_ONE_SHOT)

func _now_secs() -> float:
	return float(Time.get_ticks_msec()) / 1000.0

func _is_cooldown_active(body: Node) -> bool:
	var id := body.get_instance_id()
	var until_time: float = _cooldown_until_by_body.get(id, 0.0)
	return _now_secs() < until_time

func _start_cooldown(body: Node) -> void:
	var id := body.get_instance_id()
	_cooldown_until_by_body[id] = _now_secs() + teleport_cooldown_sec

func spawn_portal_f(pos: Vector2, normal: Vector2 = Vector2.RIGHT, face_key: String = "") -> void:
	# Green portal
	if _portal_green == null:
		_bind_portals()
	if _portal_green:
		# If we are moving green somewhere else, play its destroy there first
		if _color_to_face.has("green"):
			_spawn_destroy_ghost(_portal_green, "green")
			_clear_mapping_for_color("green")
		_evict_if_face_occupied(face_key)
		_portal_green.global_position = pos
		_set_destination_by_normal(_portal_green, normal)
		_activate_portal(_portal_green)
		_play_color_create(_portal_green, "green")
		_green_active = true
		if face_key != "":
			_face_to_color[face_key] = "green"
			_color_to_face["green"] = face_key
		print("Portal GREEN spawned at ", pos, " n=", normal)

func spawn_portal_g(pos: Vector2, normal: Vector2 = Vector2.RIGHT, face_key: String = "") -> void:
	# Purple portal
	if _portal_purple == null:
		_bind_portals()
	if _portal_purple:
		# If we are moving purple somewhere else, play its destroy there first
		if _color_to_face.has("purple"):
			_spawn_destroy_ghost(_portal_purple, "purple")
			_clear_mapping_for_color("purple")
		_evict_if_face_occupied(face_key)
		_portal_purple.global_position = pos
		_set_destination_by_normal(_portal_purple, normal)
		_activate_portal(_portal_purple)
		_play_color_create(_portal_purple, "purple")
		_purple_active = true
		if face_key != "":
			_face_to_color[face_key] = "purple"
			_color_to_face["purple"] = face_key
		print("Portal PURPLE spawned at ", pos, " n=", normal)

func _evict_if_face_occupied(face_key: String) -> void:
	if face_key == "":
		return
	if not _face_to_color.has(face_key):
		return
	var color: String = _face_to_color[face_key]
	print("Replacing existing portal on face ", face_key, " (", color, ")")
	if color == "green":
		# Replacement by other color: remove immediately (no destroy animation)
		_deactivate_portal(_portal_green)
		_green_active = false
	else:
		# Replacement by other color: remove immediately (no destroy animation)
		_deactivate_portal(_portal_purple)
		_purple_active = false
	_face_to_color.erase(face_key)
	_color_to_face.erase(color)

func _on_green_body_entered(body: Node2D) -> void:
	if not _green_active or not _purple_active:
		print("Green portal ignored enter: active=", _green_active, ", other=", _purple_active)
		return
	if body == null or not body.is_in_group(player_group):
		print("Green portal enter non-player or null: ", body)
		return
	if _is_cooldown_active(body):
		return
	print("Green portal teleporting ", body.name)
	var dest := _portal_purple.get_node_or_null("Destination") as Marker2D
	if dest:
		body.global_position = dest.global_position
		_start_cooldown(body)

func _on_purple_body_entered(body: Node2D) -> void:
	if not _green_active or not _purple_active:
		print("Purple portal ignored enter: active=", _purple_active, ", other=", _green_active)
		return
	if body == null or not body.is_in_group(player_group):
		print("Purple portal enter non-player or null: ", body)
		return
	if _is_cooldown_active(body):
		return
	print("Purple portal teleporting ", body.name)
	var dest := _portal_green.get_node_or_null("Destination") as Marker2D
	if dest:
		body.global_position = dest.global_position
		_start_cooldown(body)
