extends SceneTree
## v0.17 runtime: optional-media fallbacks, the GPU hill field matching the CPU
## elevation formula, roadside grass on that field, shared road rows, course-frame
## caching, three interface fixes and frame-rate independent jumps.
var game
var checks := 0
var failures := 0
const MediaPack = preload("res://scripts/media.gd")

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ", label)

## The original v0.16 elevation algorithm, kept here as the reference.
func reference_height(point: Vector2, samples: PackedVector3Array) -> float:
	var route = game.route
	var flat_junction := 0.0
	if game.stage == 4:
		var a: float = route.heading(route.progress)
		var canonical: Vector2 = route.course(route.progress) + Vector2(cos(a), sin(a)) * point.x + Vector2(-sin(a), cos(a)) * point.y
		flat_junction = 1.0 - smoothstep(80.0, 140.0, canonical.x)
	var closest := 10000000.0
	var elevation: float = -22.0 - route.height_at(route.progress)
	for i in range(samples.size() - 1):
		var a := Vector2(samples[i].x, samples[i].z)
		var b := Vector2(samples[i + 1].x, samples[i + 1].z)
		var along := clampf((point - a).dot(b - a) / maxf(a.distance_squared_to(b), 0.01), 0.0, 1.0)
		var distance := point.distance_squared_to(a.lerp(b, along))
		if distance < closest:
			closest = distance
			elevation = lerpf(samples[i].y, samples[i + 1].y, along) - 0.85
	var heading: float = route.heading(route.progress)
	var c: Vector2 = route.course(route.progress) + Vector2(cos(heading), sin(heading)) * point.x + Vector2(-sin(heading), cos(heading)) * point.y
	var rolling: float = -9.0 + sin(c.x * 0.024) * 5.0 + sin(c.y * 0.021 + c.x * 0.012) * 6.0 + sin(c.x * 0.061 + c.y * 0.038) * 1.8
	var field := lerpf(elevation, rolling - route.height_at(route.progress), smoothstep(14.0, 95.0, sqrt(closest)))
	return lerpf(field, -0.055 - route.height_at(route.progress), flat_junction)

func pad(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	e.pressed = true
	return e

func enter(level: int, progress: float) -> void:
	game.stage = level; game.stage_seen = level; game.elapsed = level * game.STAGE_LENGTH
	game.route.enter(level); game.route.progress = progress
	game.world.travel = progress

func jump_peak(level: int, fps: int) -> float:
	game.start_chase()
	enter(level, 0.0)
	game.speed = game.CRUISE_SPEEDS[level]
	var peak := 0.0
	var t := 0.0
	while t < 14.0:
		game.route.step(1.0 / fps)
		peak = maxf(peak, game.route.air_height)
		t += 1.0 / fps
	return peak

func run() -> void:
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"
	game = load("res://main.tscn").instantiate()
	game.settings_path = "user://runtime-tests.cfg"
	root.add_child(game)
	await process_frame
	game.save_enabled = false
	game.start_chase()
	game.set_process(false); game.world.set_process(false)
	var w = game.world

	# --- Optional media -----------------------------------------------------------
	check(MediaPack.available("res://assets/art/truck.png") and not MediaPack.available("res://assets/audio/not-a-real-take.wav"), "media availability distinguishes installed and absent files")
	var honest := true
	for path in MediaPack.MEDIA_PACK:
		honest = honest and MediaPack._installed(path) == FileAccess.file_exists(path)
	check(honest, "an .import file alone never counts as installed media")
	var clay := MediaPack.texture("res://assets/art/terrain/__absent__.png", "clay")
	var atlas := MediaPack.texture("res://assets/art/__absent_atlas__.png", "building")
	var cow := MediaPack.texture("res://assets/art/__absent_cow__.png", "cow")
	check(clay != null and clay.get_width() == 256 and atlas.get_width() == 256 and cow.get_width() == 384 and cow.get_image().detect_alpha() != Image.ALPHA_NONE, "missing textures get generated in-memory stand-ins")
	check(not FileAccess.file_exists("res://assets/art/terrain/__absent__.png") and not FileAccess.file_exists("res://assets/art/__absent_cow__.png"), "stand-ins are never written over asset paths")
	var silent := MediaPack.audio("res://assets/audio/not-a-real-take.wav") as AudioStreamWAV
	check(silent != null and absf(silent.get_length() - 0.5) < 0.01 and MediaPack.audio("res://assets/audio/not-a-real-take.wav") != silent, "missing sounds become separate short silent clips")
	var stand_in := MediaPack.stand_in_film
	MediaPack.stand_in_film = ""
	check(MediaPack.video("res://assets/cinematics/not-a-film.ogv") == null, "missing films report unavailable so the in-engine fallbacks run")
	MediaPack.stand_in_film = stand_in
	var bodywork := w.truck.body.get_node("Reference bodywork") as MeshInstance3D
	check(bodywork != null and (bodywork.material_override as ShaderMaterial).get_shader_parameter("truck_art") != null, "the approved truck scene loads with its reference bodywork texture")
	game.return_to_menu()
	var film_buttons: Array = game.hud.buttons.filter(func(b): return b.text == "WATCH STORM FILM")
	check(film_buttons.size() == 1 and film_buttons[0].disabled == not game.has_storm_film(), "the storm film button is disabled only when the film is absent")
	game.start_chase()
	game.set_process(false)

	# --- Hill field parity ------------------------------------------------------------
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	var worst := 0.0
	for level in [4, 5, 6]:
		for progress in [0.0, 96.0, 151.5, 244.0, 612.0, 1333.0]:
			enter(level, progress)
			var samples := PackedVector3Array()
			for row in range(38): samples.append(w.surface_point(30.0 - row * 12.0))
			for i in range(60):
				var p := Vector2(rng.randf_range(-520.0, 520.0) if i % 3 == 0 else rng.randf_range(-60.0, 60.0), rng.randf_range(-430.0, 50.0))
				worst = maxf(worst, absf(w._field_height(p, samples) - reference_height(p, samples)))
	check(worst < 0.01, "optimized elevation field matches the original formula (worst %.5f)" % worst)
	enter(5, 200.0)
	var rows := {}
	var row_match := true
	for z in [21.0, -3.0, -120.0, -300.0, -405.0]:
		var r: Array = w._road_row(z, rows)
		for lateral in [-9.0, -5.5, 0.0, 7.0]:
			row_match = row_match and (r[0] + r[1] * lateral).distance_to(w.surface_point(z, lateral)) < 0.001
	check(row_match, "shared road rows reproduce every road and shoulder vertex position")

	# --- Static GPU hill grid ------------------------------------------------------------
	var field: MeshInstance3D = w.terrain_field
	var arrays: Array = field.mesh.surface_get_arrays(0)
	check(arrays[Mesh.ARRAY_VERTEX].size() == 80 * 17 and arrays[Mesh.ARRAY_INDEX].size() == 79 * 16 * 6 and field.custom_aabb.size.y >= 150.0, "hill grid is a single static mesh with a real culling height")
	var mesh_before: Mesh = field.mesh
	enter(6, 300.0)
	w.mesh_level = -1
	w._update_view(0.0)
	var mat: ShaderMaterial = field.material_override
	check(field.visible and field.mesh == mesh_before and bool(mat.get_shader_parameter("terrain_field")) and int(mat.get_shader_parameter("road_sample_count")) == 38 and absf(float(mat.get_shader_parameter("field_base")) - game.route.height_at(300.0)) < 0.0001, "hills update shader inputs without rebuilding the grid")
	enter(3, 100.0)
	w._update_view(0.0)
	check(not field.visible and not w.terrain.visible, "hill grid is hidden outside the three hill levels")

	# --- Roadside grass on the GPU field ------------------------------------------------
	# Headless runs use the dummy renderer, which does not keep MultiMesh transforms, so
	# the per-cycle course cache that feeds them is checked against per-frame placement.
	var land = w.landscape
	var grass_mat: ShaderMaterial = land.grass_material
	var shared := true
	var placed := true
	# Same progress in consecutive levels: only the level change can invalidate the cache.
	for progress in [300.0, 300.4, 377.9, 911.3]:
		for level in [4, 5, 6]:
			enter(level, progress)
			w._update_view(0.0)
			for key in ["road_samples", "road_sample_count", "field_origin", "field_heading", "field_base", "field_junction", "field_bounds"]:
				shared = shared and grass_mat.get_shader_parameter(key) == mat.get_shader_parameter(key)
			shared = shared and bool(grass_mat.get_shader_parameter("terrain_field"))
			for i in range(land.grass.visible_instance_count):
				var along: float = i * 1.27 - w.travel
				var z: float = 24.0 - fposmod(along, 260.0)
				var lateral := (-1.0 if i % 2 == 0 else 1.0) * (9.7 + fmod(i * 3.79, 35.0))
				var tuft: Vector3 = game.route.project_point(land.grass_course[i], land.grass_height[i])
				placed = placed and land.grass_cycle[i] == floori(along / 260.0) and tuft.distance_to(w.surface_point(z, lateral)) < 0.001
	check(shared, "roadside grass reads the same hill-field inputs as the hill grid")
	check(placed, "cached grass positions match per-frame placement across scroll cycles")
	enter(1, 140.0)
	w._update_view(0.0)
	var flat_grass := not bool(grass_mat.get_shader_parameter("terrain_field"))
	enter(5, 140.0)
	w._update_view(0.0)
	check(flat_grass and bool(grass_mat.get_shader_parameter("terrain_field")), "grass follows the hill field only in the hill levels")

	# --- Course frame cache ------------------------------------------------------------
	enter(6, 180.0)
	var first: Vector3 = game.route.point(-40.0, 3.0)
	game.route.progress = 420.0
	var moved: Vector3 = game.route.point(-40.0, 3.0)
	var s := 420.0 + 40.0
	var a: float = game.route.heading(s)
	var origin: Vector2 = game.route.course(420.0)
	var h0: float = game.route.heading(420.0)
	var delta: Vector2 = game.route.course(s) + Vector2(cos(a), sin(a)) * 3.0 - origin
	var expected := Vector3(delta.dot(Vector2(cos(h0), sin(h0))), game.route.height_at(s) - game.route.height_at(420.0), delta.dot(Vector2(-sin(h0), cos(h0))))
	check(first.distance_to(moved) > 1.0 and moved.distance_to(expected) < 0.0001, "course frame refreshes whenever progress changes")
	game.route.enter(5)
	game.route.progress = 420.0
	var other_level: Vector3 = game.route.point(-40.0, 3.0)
	check(other_level.distance_to(moved) > 0.01, "course frame refreshes when the level changes at the same progress")

	# --- Interface fixes ----------------------------------------------------------------
	enter(6, 100.0)
	game.message = "AIRBORNE  /  LINE UP YOUR LANDING"; game.message_time = 2.0
	game.route.hint = "AIRBORNE  /  STRAIGHTEN BEFORE LANDING"
	var repeats: bool = game.hud._hint_repeats_message()
	game.route.hint = "RIGHT BEND  /  EASE OFF BOOST"
	var distinct: bool = not game.hud._hint_repeats_message()
	game.route.hint = "AIRBORNE  /  STRAIGHTEN BEFORE LANDING"
	game.message_time = 0.0
	check(repeats and distinct and not game.hud._hint_repeats_message(), "a route hint is hidden only while a notice on the same topic is showing")
	game.finish(false, "Runtime test.")
	game.hud.rebuild()
	var footage: Array = game.hud.buttons.filter(func(b): return b.text == "MATEO'S FOOTAGE")
	check(game.mode == game.Mode.RESULTS and footage.size() == 1 and game.hud.RESULTS_PANEL.encloses(Rect2(footage[0].position, footage[0].size)), "the debrief's footage button sits inside the results panel")
	var closes := true
	for button in [JOY_BUTTON_B, JOY_BUTTON_START]:
		game.return_to_menu()
		if game.has_storm_film():
			game.show_film()
		else:
			# The real film is absent from trimmed copies; use the same overlay with a bare player.
			game.film_overlay = Control.new(); game.add_child(game.film_overlay)
			game.film_player = VideoStreamPlayer.new(); game.film_overlay.add_child(game.film_player)
		var opened: bool = is_instance_valid(game.film_overlay)
		game._unhandled_input(pad(button))
		closes = closes and opened and game.film_overlay == null and game.mode == game.Mode.MENU
	check(closes, "controller B or Start closes the title storm film")

	# --- Frame-rate independent jumps -------------------------------------------------
	var consistent := true
	for level in [5, 6]:
		var slow := jump_peak(level, 30)
		var fast := jump_peak(level, 120)
		print("JUMP_PEAK level=", level, " 30fps=", snappedf(slow, 0.01), " 120fps=", snappedf(fast, 0.01))
		consistent = consistent and fast > 0.5 and absf(slow - fast) / fast < 0.03
	check(consistent, "big-hill jump height stays within 3% between 30 and 120 FPS")

	print("RUNTIME_TESTS ", checks, " checks; ", failures, " failures")
	game.queue_free(); await process_frame
	quit(0 if failures == 0 else 1)
