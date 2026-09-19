extends Control

const LENGTH: = 8.6
const FILM_LENGTH := 6.0
const FILMS := {
	1: "res://assets/cinematics/checkpoints/barn.ogv",
	2: "res://assets/cinematics/checkpoints/warehouse.ogv",
	3: "res://assets/cinematics/checkpoints/crosswind_curves.ogv",
	4: "res://assets/cinematics/checkpoints/dirt_shortcut.ogv",
	5: "res://assets/cinematics/checkpoints/ridgeline_drift.ogv",
	6: "res://assets/cinematics/checkpoints/wild_hills.ogv",
	7: "res://assets/cinematics/checkpoints/vortex_run.ogv"
}
const TITLES: = ["", "BARN BREAKOUT", "WAREHOUSE COLLAPSE"]
const CAPTIONS: = ["", "Timber. Barn doors. Torn roofing.", "Concrete. Steel beams. Metal cladding."]
const SITES: = ["", "SILO COUNTY / CHECKPOINT 01", "FREIGHT DISTRICT / CHECKPOINT 02"]
const AMBER: = Color("f4bc63")
const WHITE: = Color("ecf0e9")
const MINT: = Color("84dfb9")
const DISPLAY: = preload("res://assets/fonts/display.ttf")
const MONO: = preload("res://assets/fonts/telemetry.ttf")
const Media := preload("res://scripts/media.gd")
var game: Node2D
var active: = false
var route_preview := false
var age: = 0.0
var site_theme: = 1
var building: Node3D
var pieces: Array[Dictionary] = []
var clouds: Array[Dictionary] = []
var origin: = Vector3(13, 0, -38)
var r: = RandomNumberGenerator.new()
var impact_played: = false
var pass_played: = false
var entry_truck: = Vector3.ZERO
var entry_camera: = Vector3.ZERO
var entry_fov: = 66.0
var movies_enabled := true
var film_playing := false
var player: VideoStreamPlayer
var film_layer: Control
var paused_audio: Dictionary = {}
var return_fade: ColorRect
var fade_left := 0.0

func _ready() -> void :
	z_index = 110
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func reset() -> void :
	_stop_movie()
	fade_left = 0.0
	return_fade = null
	active = false;age = 0.0
	hide()
	if is_instance_valid(building): building.free()
	building = null;pieces.clear();clouds.clear()
	for child in get_children():
		if child is CanvasItem: child.hide()
		child.queue_free()
	if is_instance_valid(game.world.mateo): game.world.mateo.reset_pose()

func begin(next_theme: int) -> void :
	reset()
	site_theme = clampi(next_theme, 1, 7)
	route_preview = site_theme >= 3
	game.mode = game.Mode.CHECKPOINT
	game.dodges.cancel_pending()
	game._clear_touch()

	game.debris.clear();game.effects.clear();game.sky_debris.clear()
	game._reset_water()
	game.lens_projectiles.clear();game.lens_marks.clear();game.skid_trails.clear()
	game.shake = 0;game.flash = 0;game.lens_kick = 0;game.flyby_pressure = 0
	game.crashes.reset()
	entry_truck = game.world.truck.position
	entry_camera = game.world.camera.position
	entry_fov = game.world.camera.fov
	r.seed = 4112 + site_theme
	origin = Vector3(20 if site_theme == 1 else 25, 0, -38 if site_theme == 1 else -43)
	if not _start_movie() and not route_preview: _build_site()
	impact_played = false;pass_played = false;active = true
	show()
	var skip: = Button.new()
	skip.text = "KEEP CHASING  >"
	skip.position = Vector2(1030, 666);skip.size = Vector2(216, 36)
	skip.add_theme_font_override("font", DISPLAY)
	skip.add_theme_font_size_override("font_size", 14)
	skip.add_theme_color_override("font_color", WHITE)
	skip.add_theme_stylebox_override("normal", game.hud.style(Color("19363d"), Color("456366"), 5))
	skip.add_theme_stylebox_override("hover", game.hud.style(Color("29474d"), AMBER, 5))
	skip.focus_mode = Control.FOCUS_NONE
	skip.pressed.connect(complete.bind(false))
	add_child(skip)
	game.hud.rebuild()
	apply_view()

func _start_movie() -> bool:
	if not movies_enabled or not FILMS.has(site_theme): return false
	var path: String = FILMS[site_theme]
	var stream := Media.video(path)
	if stream == null: return false
	film_layer = Control.new()
	film_layer.z_index = -1
	film_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(film_layer)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.size = size
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	film_layer.add_child(black)
	player = VideoStreamPlayer.new()
	player.stream = stream
	var grade := ShaderMaterial.new()
	grade.shader = preload("res://shaders/cinematic_grade.gdshader")
	player.material = grade
	player.expand = true
	player.size = size
	if site_theme in [3, 4, 5, 6, 7]:
		# Preserve the supplied frame's aspect ratio and the truck's proportions.
		player.size.x = size.y * 898.0 / 512.0
		player.position.x = (size.x - player.size.x) * 0.5
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	film_layer.add_child(player)
	film_layer.modulate.a = 0.0
	player.finished.connect(complete.bind(false))
	for child in game.get_children():
		if child is AudioStreamPlayer:
			paused_audio[child] = child.stream_paused
			child.stream_paused = true
	film_playing = true
	player.play()
	return true

func _stop_movie() -> void:
	film_playing = false
	if is_instance_valid(player):
		player.stop()
		player.stream = null
	player = null
	if is_instance_valid(film_layer):
		film_layer.hide()
		film_layer.queue_free()
	film_layer = null
	for audio in paused_audio:
		if is_instance_valid(audio): audio.stream_paused = paused_audio[audio]
	paused_audio.clear()

func _fallback_to_scene() -> void:
	_stop_movie()
	age = 0.0
	impact_played = false
	pass_played = false
	if not route_preview: _build_site()
	apply_view()

func _fade_to_chase() -> void:
	return_fade = ColorRect.new()
	return_fade.size = size
	return_fade.color = Color.BLACK
	return_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return_fade.z_index = 1
	add_child(return_fade)
	fade_left = 0.22
	show()

func _exit_tree() -> void:
	_stop_movie()

func _piece(pos: Vector3, size3: Vector3, mat: Material, rotation3: Vector3 = Vector3.ZERO, roof: bool = false) -> void :
	var n: MeshInstance3D = game.world.box(building, pos, size3, mat)
	n.rotation = rotation3
	var launch: = Vector3(r.randf_range(-9.5, 2.0), r.randf_range(7, 14), r.randf_range(7, 14))
	var delay: = 2.55 + r.randf_range(0, 0.7)
	if roof:
		delay = 1.95 + r.randf_range(0, 0.42)
		launch.y += 4.0
	pieces.append({"node": n, "base": pos, "rot": rotation3, "velocity": launch, "spin": Vector3(r.randf_range(-2, 2), r.randf_range(-2, 2), r.randf_range(-2, 2)), "delay": delay, "hero": false})

func _build_site() -> void :
	building = Node3D.new()
	building.name = "Barn destruction" if site_theme == 1 else "Warehouse destruction"
	game.world.space.add_child(building)
	building.position = origin
	var wall: Material = game.world.building_materials[0 if site_theme == 1 else 2]
	var roof: Material = game.world.building_materials[1 if site_theme == 1 else 3]
	var frame: Material = game.world.mat_wood if site_theme == 1 else game.world.building_materials[3]
	var width: = 18.0 if site_theme == 1 else 24.0
	var height: = 7.2 if site_theme == 1 else 9.4
	var depth: = 13.0 if site_theme == 1 else 15.0
	game.world.box(building, Vector3(0, 0.05, 0), Vector3(width + 1, 0.22, depth + 1), game.world.building_materials[2])

	for side in [-1.0, 1.0]:
		for col in range(6):
			for row in range(2):
				if side > 0 and col in [2, 3] and row == 0: continue
				_piece(Vector3( - width * 0.5 + (col + 0.5) * width / 6, (row + 0.5) * height / 2, side * depth / 2), Vector3(width / 6 - 0.06, height / 2 - 0.03, 0.19), wall)
		for col in range(5):
			_piece(Vector3(side * width / 2, height / 2, - depth * 0.5 + (col + 0.5) * depth / 5), Vector3(0.2, height, depth / 5 - 0.04), wall)
			_piece(Vector3(side * width / 2, height / 2, - depth * 0.5 + col * depth / 4), Vector3(0.28, height, 0.28), frame)

	for side in [-1.0, 1.0]:
		_piece(Vector3(side * width / 12, height * 0.24, depth / 2 + 0.12), Vector3(width / 6 - 0.1, height * 0.48, 0.15), wall if site_theme == 1 else roof)
		if site_theme == 1:
			_piece(Vector3(side * width / 12, height * 0.24, depth / 2 + 0.23), Vector3(0.16, height * 0.59, 0.12), game.world.mat_silver, Vector3(0, 0, side * 0.63))
	for col in range(5):
		var z: = - depth * 0.5 + col * depth / 4
		_piece(Vector3(0, height, z), Vector3(width, 0.24, 0.24), frame, Vector3.ZERO, true)
		for side in [-1.0, 1.0]:
			for tile in range(3):
				var x: float = side * (tile + 0.5) * width / 6
				var peak: = (width / 2 - absf(x)) * 0.39 if site_theme == 1 else 0.12
				_piece(Vector3(x, height + peak, z), Vector3(width / 6 + 0.12, 0.13, depth / 4 + 0.07), roof, Vector3(0, 0, - side * 0.37 if site_theme == 1 else 0.0), true)
	if site_theme == 1:

		for side in [-1.0, 1.0]:
			for col in range(10):
				var x: = - width / 2 + (col + 0.5) * width / 10
				var h: = (width / 2 - absf(x)) * 0.39
				_piece(Vector3(x, height + h / 2, side * depth / 2), Vector3(width / 10 - 0.04, maxf(0.15, h), 0.17), wall)
	var sign: = Label3D.new()
	sign.text = "SILO COUNTY" if site_theme == 1 else "FREIGHT  /  07"
	sign.font = DISPLAY;sign.font_size = 68;sign.pixel_size = 0.01
	sign.modulate = Color("c7c7ad");sign.outline_size = 8
	_piece(Vector3(0, height * 0.79, depth / 2 + 0.25), Vector3(5.2, 0.85, 0.12), frame)
	sign.position = Vector3(0, 0, 0.08)
	pieces[-1].node.add_child(sign)

	for kind in [0, 3, 1]:
		var hero: Node3D = game.world._hazard(kind, site_theme)
		building.add_child(hero)
		hero.scale = Vector3.ONE * 1.65
		var pos: = Vector3(r.randf_range(-4, 4), height, 2)
		pieces.append({"node": hero, "base": pos, "rot": Vector3.ZERO, "velocity": Vector3.ZERO, "spin": Vector3(1.6, -1.1, 1.5), "delay": 3.3 + kind * 0.21, "hero": true, "side": -1.0 if kind == 0 else 1.0})
	for i in range(26):
		var quad: = QuadMesh.new()
		quad.size = Vector2.ONE
		var mat: = ShaderMaterial.new()
		mat.shader = preload("res://shaders/destruction_dust.gdshader")
		mat.set_shader_parameter("tint", Vector3(0.3, 0.3, 0.26) if site_theme == 1 else Vector3(0.35, 0.39, 0.39))
		var cloud: MeshInstance3D = game.world.mesh_node(building, quad, Vector3.ZERO, mat)
		cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cloud.visible = false
		clouds.append({"node": cloud, "mat": mat, "pos": Vector3(r.randf_range( - width / 2, width / 2), r.randf_range(1, 6), r.randf_range(-5, 5)), "phase": r.randf() * TAU, "delay": 2.5 + i * 0.035})

func _process(dt: float) -> void :
	if fade_left > 0.0:
		fade_left = maxf(0.0, fade_left - dt)
		if is_instance_valid(return_fade):
			return_fade.color.a = fade_left / 0.22
			if fade_left == 0.0:
				return_fade.queue_free()
				return_fade = null
				if not active: hide()
	if not active: return
	step(minf(dt, 0.05))

func step(dt: float) -> void :
	if not active: return
	age += dt
	if film_playing:
		if is_instance_valid(film_layer): film_layer.modulate.a = smoothstep(0.0,0.4,age)
		# Completion follows decoded playback, not the previous scene timer.
		# A stopped or stalled decoder falls back to the in-engine scene.
		if (age > 0.75 and (not is_instance_valid(player) or not player.is_playing())) or age > FILM_LENGTH + 4.0:
			_fallback_to_scene()
		queue_redraw()
		return
	if route_preview:
		apply_view()
		queue_redraw()
		if age >= 2.8: complete()
		return
	if age >= 2.55 and not impact_played:
		impact_played = true
		game.play_sound("thunder");game.play_sound("hit");game.play_sound("heavy_pass")
	if age >= 5.8 and not pass_played:
		pass_played = true
		game.play_sound("heavy_pass");game.play_sound("pass_left")
	apply_view()
	queue_redraw()
	if age >= LENGTH: complete()

func apply_view() -> void :
	if not active or film_playing: return
	if route_preview:
		var camera = game.world.camera
		camera.position = Vector3(-0.8+age*0.25,4.0,12.5-age*0.4)
		camera.fov = 62.0
		camera.look_at(Vector3(2.0,4.1,-30),Vector3.UP)
		game.world.mateo.cinematic_pose(game.elapsed+age,false)
		return
	if not is_instance_valid(building): return
	var w: Node2D = game.world

	var settle: = smoothstep(0.0, 1.4, age)
	var returning: = smoothstep(7.35, LENGTH, age)
	var cam: = Vector3(0.35 + sin(age * 0.32) * 0.25, 3.7 + smoothstep(1.9, 5.6, age) * 0.1, 14.2)
	var focus: = Vector3(2.8, 3.8, -25.0)
	cam = entry_camera.lerp(cam, settle)
	w.camera.position = cam.lerp(Vector3(w.camera_pan, 3.4, 10), returning)
	w.camera.fov = lerpf(lerpf(entry_fov, 59.0, settle), 66.0, returning)
	w.camera.look_at(focus.lerp(Vector3(w.camera_pan * 0.75, 3.9, -29), returning), Vector3.UP)
	var jolt: = maxf(0.0, 1.0 - absf(age - 2.8) / 0.45)
	if not game.calm_fx:
		w.camera.position += Vector3(sin(age * 61), cos(age * 49), 0) * jolt * 0.1
	w.truck.position = entry_truck + Vector3(sin(age * 4) * 0.035, 0.015 * sin(age * 22), 0)
	w.truck.rotation = Vector3(0, sin(age * 2.4) * 0.045, 0)
	var storm_x: = lerpf(39.0, origin.x, smoothstep(0.5, 2.9, age))
	var storm_z: float = -135.0 - (game.distance - 800.0) * 0.025
	var chase_storm: = Vector3(w.road_center(storm_z) + game.storm_offset * 45.0, 70, storm_z)
	w.tornado.position = Vector3(storm_x, 70, origin.z - 7.0).lerp(chase_storm, returning)
	building.position = origin + Vector3(0, 0, - returning * 180)
	for i in range(w.orbit_nodes.size()):
		var u: = i / 42.0
		var angle: = age * (1.9 + u) + i * 2.4
		w.orbit_nodes[i].position = w.tornado.position + Vector3(sin(angle) * (8 + u * 12), -64 + u * 105, cos(angle) * (8 + u * 12))
		w.orbit_nodes[i].rotation = Vector3(angle, angle * 0.7, angle * 0.4)
	w.storm_material.set_shader_parameter("clock", (game.elapsed + age) * 1.8)
	w.storm_material.set_shader_parameter("brightness", 0.72 + (0.0 if game.calm_fx else jolt * 0.3))
	w.sun.light_energy = 1.55 + (0.0 if game.calm_fx else jolt * 1.1)
	w.mateo.cinematic_pose(game.elapsed + age, age > 5.45 and age < 7.4)
	for n in w.hazard_nodes: n.visible = false
	for n in w.sky_nodes: n.visible = false
	for n in w.turbines: n.visible = false

	var action_time: = age if age < 2.65 else (2.65 + (age - 2.65) * 0.48 if age < 4.15 else 3.37 + (age - 4.15) * 1.25)
	for p in pieces:
		var t: = maxf(0.0, action_time - float(p.delay))
		var n: Node3D = p.node
		if p.hero:
			n.visible = t > 0 and t < 2.2
			var u: = clampf(t / 2.2, 0, 1)
			var target: = Vector3(game.player_x * 5.8 + float(p.side) * 1.7, 2.8, 16.0) - origin
			n.position = Vector3(p.base).lerp(target, pow(u, 1.55)) + Vector3(0, sin(u * PI) * 3.8, 0)
		else:
			var v: Vector3 = p.velocity
			n.position = Vector3(p.base) + v * t + Vector3(sin(t * 2.3) * t * 1.4, -1.1 * t * t, 0)
			n.visible = t < 4.7
			n.position.y = maxf(0.25, n.position.y)
		n.rotation = Vector3(p.rot) + Vector3(p.spin) * t
	for cloud in clouds:
		var t: = maxf(0.0, action_time - float(cloud.delay))
		var n: MeshInstance3D = cloud.node
		n.visible = t > 0 and t < 4.8
		n.position = Vector3(cloud.pos) + Vector3( - t * 1.8, t * 2.4, t * 3.8)
		n.scale = Vector3.ONE * (3.0 + t * 5.0)
		n.look_at(w.camera.global_position, Vector3.UP, true)
		cloud.mat.set_shader_parameter("clock", age + float(cloud.phase))
		cloud.mat.set_shader_parameter("opacity", minf(t * 1.6, 0.48) * (1.0 - smoothstep(2.5, 4.8, t)))

func complete(pause_after: bool = false) -> void :
	if not active: return
	var was_film := film_playing
	reset()
	game.mode = game.Mode.RUNNING
	game.speed = game.CRUISE_SPEEDS[game.stage]
	game._reset_water()
	game.velocity_x = 0;game.rear_slip = 0;game.rear_slip_velocity = 0;game.steer = 0
	game.boosting = false;game.turbo_fx = 0;game.lightning = 0
	game.distance = clampf(game.distance, 500, 1100)
	game.invulnerable = 2.0;game.spawn_timer = 1.25;game.sky_timer = 3.5;game.lens_timer = 7.0
	game._clear_touch()
	game.unlock_footage(game.stage)
	game.save_checkpoint()
	game.notify("CHECKPOINT %02d SAVED  /  %s" % [game.stage, (game.route.chapter_caption() if game.stage>=3 else CAPTIONS[game.stage]).to_upper()], 3.5)
	game.hud.rebuild()
	game.world._update_view(0)
	game.cinematic_return = 1.0
	if pause_after: game.pause_chase()
	if was_film: _fade_to_chase()

func handle_input(event: InputEvent) -> void :
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_ESCAPE]: complete()
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_START]: complete()
	get_viewport().set_input_as_handled()

func _draw() -> void :
	if not active: return
	var ink: = Color(0.015, 0.03, 0.038, 0.96)
	draw_rect(Rect2(0, 0, 1280, 48), ink)
	draw_rect(Rect2(0, 621, 1280, 99), ink)
	draw_string(MONO, Vector2(34, 30), ("LEVEL %02d / CHECKPOINT %02d" % [site_theme+1,site_theme] if route_preview else SITES[site_theme]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, AMBER)
	draw_circle(Vector2(1068, 24), 3, Color(1, 0.24, 0.2, 0.6 + 0.4 * sin(age * 5)))
	draw_string(MONO, Vector2(1082, 29), "STORM / REC" if film_playing else "MATEO / REC", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, WHITE)
	draw_string(DISPLAY, Vector2(34, 659), game.STAGE_NAMES[site_theme], HORIZONTAL_ALIGNMENT_LEFT, -1, 28, WHITE)
	draw_string(MONO, Vector2(35, 691), (game.route.chapter_caption() if route_preview else CAPTIONS[site_theme]) + "  /  %d MPH" % game.CRUISE_SPEEDS[site_theme], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MINT)
	draw_string(MONO, Vector2(784, 688), "SPACE / ESC / A TO SKIP", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, AMBER)
	var progress := player.stream_position / FILM_LENGTH if film_playing and is_instance_valid(player) else age / (2.8 if route_preview else LENGTH)
	draw_rect(Rect2(0, 717, 1280 * clampf(progress, 0, 1), 3), AMBER)
