extends Node2D

var game: Node2D
const SKY: = preload("res://assets/art/storm-sky.png")
const TRUCK: = preload("res://assets/art/truck.png")
const DEBRIS: = preload("res://assets/art/debris-atlas.png")
const VORTEX: = preload("res://assets/art/tornado.png")
const SEMI: = preload("res://assets/art/flying-semi.png")
const COW: = preload("res://assets/art/flying-cow.png")
var road: ColorRect
var tornado: Sprite2D
var sky: Sprite2D
var travel: = 0.0
var camera_pan: = 0.0
var rain: Array[Vector3] = []
var small_font: = preload("res://assets/fonts/telemetry.ttf")

func _ready() -> void :
	sky = Sprite2D.new()
	sky.texture = SKY
	sky.centered = false
	sky.position = Vector2(-30, -300)
	sky.scale = Vector2(1340.0 / SKY.get_width(), 754.0 / SKY.get_height())
	sky.z_index = -5
	add_child(sky)
	road = ColorRect.new()
	road.size = Vector2(1280, 720)
	road.mouse_filter = Control.MOUSE_FILTER_IGNORE
	road.z_index = -4
	var road_material: = ShaderMaterial.new()
	road_material.shader = preload("res://shaders/road.gdshader")
	road.material = road_material
	add_child(road)
	tornado = Sprite2D.new()
	tornado.texture = VORTEX
	tornado.z_index = -3
	var vortex_material: = ShaderMaterial.new()
	vortex_material.shader = preload("res://shaders/vortex.gdshader")
	tornado.material = vortex_material
	add_child(tornado)
	var random: = RandomNumberGenerator.new()
	random.seed = 200725
	for i in range(220): rain.append(Vector3(random.randf() * 1500.0, random.randf() * 900.0, random.randf_range(0.4, 1.0)))

func _process(dt: float) -> void :
	visible = game.mode != game.Mode.MENU
	if game.mode == game.Mode.RUNNING:
		travel += minf(dt, 0.05) * game.speed * 0.22
		camera_pan = lerpf(camera_pan, - game.player_x * 55.0 - game.steer * 12.0, 1.0 - exp( - dt * 5.0))
	road.material.set_shader_parameter("travel", travel)
	road.material.set_shader_parameter("bend", game.bend)
	road.material.set_shader_parameter("horizon", horizon() / 720.0)
	road.material.set_shader_parameter("camera_x", camera_pan / 1280.0)
	road.material.set_shader_parameter("rush", game.turbo_fx)
	road.material.set_shader_parameter("stage", float(game.stage))
	road.material.set_shader_parameter("brightness", 1.0 if game.calm_fx else 1.0 + game.lightning)
	var height: = clampf(525.0 + (1000.0 - game.distance) * 0.2 + game.stage * 15.0, 360.0, 690.0)
	tornado.scale = Vector2(height / VORTEX.get_width(), height / VORTEX.get_height())
	tornado.position = Vector2(640.0 + camera_pan * 0.65 + game.storm_offset * 500.0 + game.bend * 60.0, horizon() + 24.0 - height * 0.5)
	tornado.modulate = Color(0.74, 0.81, 0.82, 0.98)
	tornado.material.set_shader_parameter("clock", game.elapsed * 1.45)
	sky.position = Vector2(-30.0 - game.storm_offset * 20.0 + camera_pan * 0.33, -300.0 + horizon() - 350.0)
	var zoom: float = 1.025 if game.calm_fx else 1.045 - game.turbo_fx * 0.025 - game.flyby_pressure * 0.012
	scale = Vector2.ONE * zoom
	position = Vector2(640, 360) * (1.0 - zoom)
	if not game.calm_fx:
		var vibration: float = 0.65 + game.speed / 180.0 + game.turbo_fx * 1.6
		position += Vector2(sin(game.elapsed * 83.0), cos(game.elapsed * 71.0)) * (game.shake + vibration)
		position.x += game.near_side * game.near_pulse * 3.5
		position += Vector2(sin(game.elapsed * 103.0) * 13.0, cos(game.elapsed * 89.0) * 9.0) * game.lens_kick
		position.y += game.flyby_pressure * 8.0

func reset_motion() -> void :
	travel = 0.0
	camera_pan = 0.0
	position = Vector2.ZERO
	rotation = 0.0

func horizon() -> float:
	return 338.0 - (9.0 if game.calm_fx else 24.0) * game.turbo_fx

func depth(z: float) -> float:

	return maxf(z, 0.0) / maxf(0.24, 2.0 - z)

func project(lane: float, z: float) -> Vector2:
	var projected: float = depth(z)
	var y: float = horizon() + (659.0 - horizon()) * projected
	var q: float = (y - horizon()) / (720.0 - horizon())
	return Vector2(640.0 + camera_pan + game.bend * 140.0 * pow(1.0 - q, 2.0) + lane * (20.0 + 589.0 * q), y)

func _draw() -> void :
	if game.mode == game.Mode.MENU: return
	_draw_scenery()
	_draw_vortex_debris()
	_draw_sky_pieces(false)
	_draw_skid_trails()
	var ordered: Array = game.debris.duplicate()
	ordered.sort_custom( func(a, b): return a.z < b.z)
	for d in ordered:
		if d.z < 1.035: _draw_debris(d)
	_draw_truck()
	for d in ordered:
		if d.z >= 1.035: _draw_debris(d)
	_draw_sky_pieces(true)
	_draw_effects()
	_draw_weather()

func _draw_scenery() -> void :

	for i in range(11):
		var z: = fposmod(float(i) / 11.0 + travel * 0.013, 1.14)
		for side in [-1.0, 1.0]:
			var base: = project(side * 1.34, z)
			var h: = 9.0 + depth(z) * 220.0
			var lean: = Vector2(game.wind * h * 0.4, - h)
			draw_line(base, base + lean, Color(0.12, 0.14, 0.13), maxf(1.0, z * 6.0), true)
			draw_line(base + lean + Vector2( - h * 0.16, h * 0.12), base + lean + Vector2(h * 0.16, h * 0.12), Color(0.11, 0.12, 0.11), maxf(1.0, z * 4.0), true)
			var next: = project(side * 1.34, z + 0.092)
			var next_h: = 9.0 + depth(z + 0.092) * 220.0
			if z < 1.02:
				var a: = base + lean + Vector2(0, h * 0.12)
				var b: = next + Vector2(game.wind * next_h * 0.4, - next_h * 0.88)
				var points: = PackedVector2Array()
				for k in range(9):
					var t: = k / 8.0
					points.append(a.lerp(b, t) + Vector2(0, sin(t * PI) * h * 0.09))
				draw_polyline(points, Color(0.12, 0.15, 0.14, 0.7), maxf(1.0, z * 1.4), true)
	for i in range(24):
		var z: = fposmod(float(i) / 24.0 + travel * 0.013, 1.14)
		for side in [-1.0, 1.0]:
			var base: = project(side * 1.1, z)
			var h: = 3.0 + depth(z) * 24.0
			draw_line(base, base + Vector2(0, - h), Color(0.44, 0.43, 0.31), maxf(1.0, z * 3.0), true)
			if not game.calm_fx and z > 0.45:
				var tail: = project(side * 1.1, z - 0.065)
				draw_line(tail, base, Color(0.86, 0.85, 0.57, 0.18), maxf(1.0, z * 2.0), true)
	if game.stage >= 1:
		for i in range(7):
			var x: float = 85.0 + i * 174.0 - game.bend * 24.0 + camera_pan * 0.4
			var h: = 35.0 + fmod(i * 23.0, 42.0)
			var hub: = Vector2(x, horizon() - 5.0 - h)
			draw_line(Vector2(x, horizon() + 1), hub, Color(0.32, 0.38, 0.36), 2.5, true)
			for arm in range(3):
				var angle: float = game.elapsed * 0.8 + arm * TAU / 3.0 + i
				var end: = hub + Vector2(cos(angle), sin(angle)) * h * 0.45
				draw_line(hub, end, Color(0.47, 0.51, 0.46), 2.0, true)

	for i in range(15):
		draw_rect(Rect2(-50, horizon() - 1 + i * 2, 1380, 2), Color(0.31, 0.39, 0.39, 0.028 * (1.0 - i / 15.0)))

func _draw_vortex_debris() -> void :
	var cx: = tornado.position.x
	for i in range(44):
		var u: = float(i) / 44.0
		var angle: float = game.elapsed * (2.6 + u * 2.2) + i * 2.4
		var radius: = 30.0 + (1.0 - u) * 155.0
		var point: = Vector2(cx + sin(angle) * radius, horizon() + 17.0 - u * 250.0 + cos(angle) * radius * 0.12)
		var size: = 1.4 + (1.0 - u) * 3.0
		draw_set_transform(point, angle)
		draw_rect(Rect2( - size, - size * 0.35, size * 2.0, size * 0.7), Color(0.15, 0.17, 0.14, 0.6))
		draw_set_transform(Vector2.ZERO)

func debris_size(z: float) -> float:
	return 24.0 + 176.0 * pow(depth(z), 1.1)

func debris_center(d: Dictionary, z: float) -> Vector2:
	var size: = debris_size(z)
	var lift_factor: float = [0.24, 0.32, 0.07, 0.42][int(d.kind)]
	var lift: float = (0.55 + absf(sin(game.elapsed * 5.0 + d.phase)) * 0.45) * size * lift_factor
	return project(d.lane, z) + Vector2(0, - size * 0.32 - lift)

func _draw_debris(d: Dictionary) -> void :
	if d.z <= 0.0: return
	var point: = project(d.lane, d.z)
	var size: = debris_size(d.z)
	var shadow: = Color(0.015, 0.025, 0.03, 0.28 + minf(0.3, d.z * 0.3))
	draw_set_transform(point, 0.0, Vector2(1, 0.21))
	draw_circle(Vector2.ZERO, size * 0.36, shadow)
	draw_set_transform(Vector2.ZERO)
	if d.kind == 4:
		var center: = point + Vector2(0, - size * 0.34)
		var pulse: = 0.7 + 0.3 * sin(game.elapsed * 5.0)
		draw_circle(center, size * 0.45, Color(0.3, 0.9, 0.7, 0.08))
		draw_arc(center, size * 0.4, 0, TAU, 28, Color(0.45, 0.95, 0.76, pulse), 2.0, true)
		var box: = Rect2(center - Vector2(size * 0.24, size * 0.22), Vector2(size * 0.48, size * 0.44))
		draw_rect(box, Color(0.07, 0.22, 0.21))
		draw_rect(box, Color(0.5, 0.98, 0.76), 2.0)
		draw_line(center - Vector2(size * 0.13, 0), center + Vector2(size * 0.13, 0), Color(0.74, 1, 0.85), maxf(2.0, size * 0.05), true)
		draw_line(center - Vector2(0, size * 0.13), center + Vector2(0, size * 0.13), Color(0.74, 1, 0.85), maxf(2.0, size * 0.05), true)
		return
	var cell: = DEBRIS.get_size() / 2.0
	var source: = Rect2(Vector2(int(d.kind) % 2, int(d.kind) / 2) * cell, cell)
	if not game.calm_fx and d.z > 0.48:

		for i in range(3, 0, -1):
			var previous_z: float = maxf(0.0, d.z - i * 0.026)
			var previous_size: = debris_size(previous_z)
			draw_set_transform(debris_center(d, previous_z), d.angle - d.spin * i * 0.025)
			draw_texture_rect_region(DEBRIS, Rect2( - previous_size * 0.5, - previous_size * 0.5, previous_size, previous_size), source, Color(0.76, 0.89, 0.91, 0.045))
			draw_set_transform(Vector2.ZERO)
	if d.z > 0.48 and d.z < 0.96:
		var marker_width: = size * 0.19
		var marker_color: = Color(1.0, 0.68, 0.24, 0.42)
		draw_polyline(PackedVector2Array([point + Vector2( - marker_width, -7), point, point + Vector2(marker_width, -7)]), marker_color, 2.0, true)
	draw_set_transform(debris_center(d, d.z), d.angle)
	draw_texture_rect_region(DEBRIS, Rect2( - size * 0.5, - size * 0.5, size, size), source, Color(0.83, 0.91, 0.92, 1))
	draw_set_transform(Vector2.ZERO)

func _draw_truck() -> void :
	var tire_line: = project(game.player_x, 1.0)
	var bounce: = sin(game.elapsed * 38.0) * minf(game.speed / 180.0, 1.2)
	var truck_center: = Vector2(tire_line.x, 545.0 + bounce + game.turbo_fx * 8.0)
	if not game.calm_fx and game.boosting: truck_center.y += sin(game.elapsed * 57.0) * 1.2
	var body_scale: float = 1.0 - game.turbo_fx * 0.035

	for side in [-1.0, 1.0]:
		var tire: = Vector2(tire_line.x + game.rear_slip * 20.0 + side * 86.0, 654.0)
		draw_set_transform(tire, 0.0, Vector2(1.0, 0.22))
		draw_circle(Vector2.ZERO, 32.0, Color(0.0, 0.02, 0.025, 0.55))
		draw_set_transform(Vector2.ZERO)
		for i in range(28):
			var t: = fposmod(game.elapsed * (4.0 + game.speed / 100.0) + i / 28.0, 1.0)
			var p: = tire + Vector2(side * t * (78.0 + game.turbo_fx * 25.0) - game.rear_slip * t * 90.0, t * 100.0)
			draw_line(p, p + Vector2(side * (8.0 + t * 9.0), 10.0 + t * 24.0), Color(0.63, 0.75, 0.77, (1.0 - t) * 0.36), 1.5 + t * 3.0, true)
		for j in range(5):
			draw_line(Vector2(tire_line.x + side * 72.0 + j * 3.0, 650.0), Vector2(tire_line.x + side * 76.0 + j * 4.0, 708.0), Color(0.9, 0.17, 0.04, 0.065), 3.0, true)
	var tint: = Color(0.9, 0.94, 0.92, 1)
	if game.invulnerable > 0.0 and sin(game.elapsed * 22.0) > 0.0: tint = Color(1, 0.78, 0.68, 0.68)
	draw_set_transform(truck_center, 0.0, Vector2(body_scale, body_scale))


	for row in range(16):
		var v0: = float(row) / 16.0
		var v1: = float(row + 1) / 16.0
		var vertices: = PackedVector2Array([truck_vertex(0.0, v0), truck_vertex(1.0, v0), truck_vertex(1.0, v1), truck_vertex(0.0, v1)])
		var uv: = PackedVector2Array([Vector2(0, v0), Vector2(1, v0), Vector2(1, v1), Vector2(0, v1)])
		draw_polygon(vertices, PackedColorArray([tint, tint, tint, tint]), uv, TRUCK)

	if fmod(game.elapsed * 2.5, 1.0) < 0.45:
		for side in [-1.0, 1.0]:
			draw_circle(Vector2(side * 36.0 - game.rear_slip * 50.0, -55.0), 10.0, Color(1, 0.55, 0.07, 0.12))
			draw_circle(Vector2(side * 36.0 - game.rear_slip * 50.0, -55.0), 5.0, Color(1, 0.7, 0.2, 0.2))
	draw_set_transform(Vector2.ZERO)

func truck_vertex(u: float, v: float) -> Vector2:
	var rear_weight: = smoothstep(0.34, 0.91, v)
	var yaw_shift: float = lerpf(-50.0, 20.0, rear_weight) * game.rear_slip
	var width_scale: float = 1.0 - absf(game.rear_slip) * 0.08
	return Vector2((u - 0.5) * 276.0 * width_scale + yaw_shift, (v - 0.5) * 276.0)

func _draw_skid_trails() -> void :
	if game.skid_trails.size() < 2: return
	for side in [-1.0, 1.0]:
		for i in range(1, game.skid_trails.size()):
			var a: Dictionary = game.skid_trails[i - 1]
			var b: Dictionary = game.skid_trails[i]
			var fade: float = (1.0 - a.age / 0.52) * a.strength
			if fade < 0.02: continue
			var p0: = project(a.lane + side * 0.185, 1.0 + a.age * 0.85)
			var p1: = project(b.lane + side * 0.185, 1.0 + b.age * 0.85)
			draw_line(p0, p1, Color(0.025, 0.045, 0.05, fade * 0.42), 9.0, true)
			draw_line(p0 + Vector2(side * 4.0, 0), p1 + Vector2(side * 4.0, 0), Color(0.67, 0.79, 0.82, fade * 0.3), 2.5, true)

func sky_piece_pose(piece: Dictionary) -> Dictionary:
	var u: float = clampf(piece.age / piece.duration, 0.0, 1.0)
	var outward: = pow(u, 2.55)
	var x: float = lerpf(piece.origin, -620.0 if piece.side < 0 else 1900.0, outward)
	var y: float = horizon() - 25.0 - sin(u * PI) * 52.0 + pow(u, 5.0) * 80.0
	var size: float = (75.0 + pow(u, 1.8) * 1230.0) if piece.kind == 0 else (35.0 + pow(u, 2.0) * 530.0)
	var angle: float = piece.side * ((-0.08 + u * 0.85) if piece.kind == 0 else (-0.25 + u * 2.0))
	return {"point": Vector2(x + camera_pan * 0.25, y), "width": size, "angle": angle, "u": u}

func _draw_sky_pieces(foreground: bool) -> void :
	for piece in game.sky_debris:
		var pose: = sky_piece_pose(piece)
		if bool(pose.u >= 0.8) != foreground: continue
		var texture: Texture2D = SEMI if piece.kind == 0 else COW
		var height: float = pose.width * texture.get_height() / texture.get_width()
		var color: = Color(0.86, 0.94, 0.96, 1.0)
		if not game.calm_fx and pose.u > 0.35:
			for i in range(3, 0, -1):
				var trail: Dictionary = piece.duplicate()
				trail.age = maxf(0.0, piece.age - i * 0.022)
				var old: = sky_piece_pose(trail)
				var old_h: float = old.width * texture.get_height() / texture.get_width()
				draw_set_transform(old.point, old.angle)
				draw_texture_rect(texture, Rect2( - old.width * 0.5, - old_h * 0.5, old.width, old_h), false, Color(0.68, 0.79, 0.85, 0.035))
				draw_set_transform(Vector2.ZERO)
		draw_set_transform(pose.point, pose.angle)
		draw_texture_rect(texture, Rect2( - pose.width * 0.5, - height * 0.5, pose.width, height), false, color)
		draw_set_transform(Vector2.ZERO)

		if piece.kind == 0 and pose.u > 0.42:
			var shadow_x: float = clampf(pose.point.x, 100.0, 1180.0)
			draw_set_transform(Vector2(shadow_x, 480.0 + pose.u * 130.0), 0, Vector2(1.0, 0.14))
			draw_circle(Vector2.ZERO, minf(pose.width * 0.6, 420.0), Color(0.015, 0.025, 0.04, 0.2 * sin(pose.u * PI)))
			draw_set_transform(Vector2.ZERO)

func _draw_effects() -> void :
	for e in game.effects:
		var p: = project(e.x, e.z)
		var alpha: float = e.life / e.max_life
		if e.type == "probe":
			draw_circle(p, 8.0, Color(0.6, 1, 0.9, alpha))
			for i in range(3):
				draw_arc(p, (1.0 - alpha) * 180.0 + i * 20.0, 0, TAU, 40, Color(0.35, 0.94, 0.8, alpha * 0.5), 2.0, true)
		else:
			for i in range(18):
				var angle: = i * 2.399
				var end: = p + Vector2(cos(angle), sin(angle)) * (1.0 - alpha) * 140.0
				draw_line(end, end + Vector2(cos(angle), sin(angle)) * 12.0, Color(1, 0.65, 0.2, alpha), 2.0, true)

func _draw_weather() -> void :
	var t: float = game.elapsed
	var count: = 85 if game.calm_fx else 185
	for i in range(count):
		var r: = rain[i]
		var p: = Vector2(fposmod(r.x - t * (205.0 + game.wind * 400.0) * r.z, 1440.0) - 80.0, fposmod(r.y + t * (700.0 + game.speed * 3.0) * r.z, 850.0) - 60.0)
		draw_line(p, p + Vector2(-9.0 - game.wind * 20.0, 25.0 + r.z * 37.0), Color(0.64, 0.78, 0.83, 0.035 + r.z * 0.075), 1.0, true)
	if not game.calm_fx:
		_draw_rush()
		if game.lightning > 0.0: draw_rect(Rect2(0, 0, 1280, 720), Color(0.61, 0.79, 0.88, game.lightning * 0.36))
		if game.flash > 0.0: draw_rect(Rect2(0, 0, 1280, 720), Color(0.78, 0.17, 0.08, game.flash * 0.2))

func _draw_rush() -> void :
	var vanishing: = Vector2(640.0 + camera_pan + game.bend * 140.0, horizon())
	var rush: float = clampf(game.speed / 240.0, 0.0, 1.0)


	for i in range(64):
		var seed_point: = rain[i]
		var u: = fposmod(travel * 0.021 + float(i) * 0.618, 1.0)
		var distance_along: = pow(u, 2.7)
		var angle: = float(i) * 2.39996
		var direction: = Vector2(cos(angle), sin(angle) * 0.64)
		var front: = vanishing + direction * (60.0 + distance_along * 1220.0)

		var peripheral: = clampf((absf(front.x - 640.0) - 190.0) / 350.0, 0.0, 1.0)
		var opacity: float = (0.08 + game.turbo_fx * 0.17) * distance_along * peripheral * rush
		var length: float = (12.0 + distance_along * (95.0 + game.turbo_fx * 90.0))
		if opacity > 0.005:
			draw_line(front - direction * length, front, Color(0.72, 0.88, 0.93, opacity), 1.0 + distance_along * 1.2, true)
		if i % 4 == 0 and front.y > horizon() + 25.0 and distance_along > 0.15:
			var shard_size: = 1.8 + distance_along * 9.0
			draw_set_transform(front, game.elapsed * (3.0 + seed_point.z) + i)
			draw_rect(Rect2( - shard_size, -1, shard_size * 2.0, 2.0 + distance_along * 2.0), Color(0.48, 0.44, 0.31, 0.35))
			draw_set_transform(Vector2.ZERO)
	if game.turbo_fx > 0.1:
		for i in range(16):
			var opacity: float = (1.0 - i / 16.0) * game.turbo_fx * 0.026
			draw_rect(Rect2(i * 5, 0, 5, 720), Color(0.25, 0.7, 0.9, opacity))
			draw_rect(Rect2(1275 - i * 5, 0, 5, 720), Color(0.25, 0.7, 0.9, opacity))
	if game.near_pulse > 0.0:
		var x: = 8.0 if game.near_side < 0.0 else 1272.0
		draw_line(Vector2(x, 290), Vector2(x, 650), Color(1.0, 0.72, 0.27, game.near_pulse * 0.75), 3.0, true)
