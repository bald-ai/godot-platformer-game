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

	_apply_visual_color()

func _apply_visual_color() -> void:
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return
	if color == ShotColor.PURPLE:
		# Use a hue-shift shader so green artwork becomes bright purple without darkening
		var mat := _make_hue_shift_material(0.42)
		sprite.material = mat
		sprite.modulate = Color(1, 1, 1)
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("purple_shoot"):
			sprite.play("purple_shoot")
		elif sprite.sprite_frames and sprite.sprite_frames.has_animation("green_shoot"):
			sprite.play("green_shoot")
	else:
		# Reset to normal for green
		sprite.material = null
		sprite.modulate = Color(1, 1, 1)
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("green_shoot"):
			sprite.play("green_shoot")

func _make_hue_shift_material(shift: float) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform float hue_shift = 0.0;

vec3 rgb2hsv(vec3 c){
	vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c){
	vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
	vec3 rgb = c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
	return rgb;
}

void fragment(){
	vec4 col = texture(TEXTURE, UV);
	vec3 hsv = rgb2hsv(col.rgb);
	hsv.x = fract(hsv.x + hue_shift);
	col.rgb = hsv2rgb(hsv);
	COLOR = col;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("hue_shift", shift)
	return mat

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
		var n: Vector2 = hit.get("normal", Vector2.RIGHT)
		var spawn_pos: Vector2 = hit.position
		var collider: Object = hit.get("collider", null)
		var face_key: String = ""
		if collider and collider is TileMap:
			var tm: TileMap = collider as TileMap
			var coords: Vector2i
			if tm.has_method("get_coords_for_body_rid"):
				var rid: RID = hit.get("rid", RID())
				coords = tm.get_coords_for_body_rid(rid)
			else:
				coords = tm.local_to_map(tm.to_local(hit.position))
			var tile_size_v: Vector2 = Vector2(tm.tile_set.tile_size.x, tm.tile_set.tile_size.y)
			var center_local: Vector2 = tm.map_to_local(coords)
			var center_global: Vector2 = tm.to_global(center_local)
			var half: Vector2 = tile_size_v * 0.5
			var eps: float = 0.5
			if abs(n.x) >= abs(n.y):
				spawn_pos = Vector2(center_global.x + sign(n.x) * (half.x - eps), center_global.y)
				var side_x: float = sign(n.x)
				face_key = str(tm.get_instance_id(), "|", coords.x, ",", coords.y, "|x|", side_x)
			else:
				spawn_pos = Vector2(center_global.x, center_global.y + sign(n.y) * (half.y - eps))
				var side_y: float = sign(n.y)
				face_key = str(tm.get_instance_id(), "|", coords.x, ",", coords.y, "|y|", side_y)
		if color == ShotColor.GREEN:
			print("Green hit at ", hit.position, " n=", n, " -> spawn ", spawn_pos, " face=", face_key)
			if _mgr and _mgr.has_method("spawn_portal_f"):
				_mgr.spawn_portal_f(spawn_pos, n, face_key)
		else:
			print("Purple hit at ", hit.position, " n=", n, " -> spawn ", spawn_pos, " face=", face_key)
			if _mgr and _mgr.has_method("spawn_portal_g"):
				_mgr.spawn_portal_g(spawn_pos, n, face_key)
		queue_free()
		return

	global_position = to
	_last_pos = global_position
