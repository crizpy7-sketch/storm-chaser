extends SceneTree
# Reaches the last part of the lap using the existing automated driver and normal
# simulation rules. The capture then shows real gameplay, the approved movie,
# results, the earned gallery card and a complete replay from the exported game.
var game
var wall := 0.0
var result_age := 0.0
var gallery_age := 0.0
var movie_started := false
var movie_natural_end := false
var replay_started := false
var replay_natural_end := false
var first_result := false
var replay_closed := false
var movie_start_time := 0.0
var movie_end_time := 0.0
var preview_end_time := 0.0
var saved_score := 0.0
var saved_records: Array = []
var shots: Dictionary = {}
var output_directory := ""

func _initialize() -> void:
	call_deferred("start")

func start() -> void:
	output_directory = OS.get_environment("STORM_CAPTURE_DIR")
	if output_directory.is_empty(): output_directory = OS.get_user_data_dir()
	game = load("res://main.tscn").instantiate()
	game.settings_path = "user://completed-game-capture-isolated.cfg"
	root.add_child(game)
	game.demo = true;game.auto_dodges = false;game.save_enabled = false
	game.rng.seed = 72611
	game.start_chase()
	for frame in range(23000):
		if game.mode == game.Mode.UPGRADE:
			game.choose_upgrade(0 if game.health < 80 else 1)
			game.checkpoints.complete()
		if game.mode != game.Mode.RUNNING: break
		if game.charge >= 100: game.deploy_probe()
		game._simulate(1.0 / 60.0)
		if game.stage == 7 and game.route.orbit_progress() >= 0.76: break
	if game.mode != game.Mode.RUNNING or game.stage != 7 or game.route.orbit_progress() < 0.76:
		printerr("COMPLETED_CAPTURE_FAILED approach mode=", game.mode);quit(1);return
	game.world._update_view(0)
	print("COMPLETED_CAPTURE_START version=", ProjectSettings.get_setting("application/config/version"), " score=", game.score, " probes=", game.probes, " hull=", game.health, " orbit=", game.route.orbit_progress())

func _process(dt: float) -> bool:
	if not is_instance_valid(game): return false
	wall += dt
	if game.mode == game.Mode.RUNNING:
		if wall > 1.0: shot("Final-Lap")
	elif game.mode == game.Mode.VORTEX:
		if not game.finale.film_playing:
			printerr("COMPLETED_CAPTURE_FAILED decoder used fallback");quit(1);return false
		if not movie_started:
			movie_started = true
			movie_start_time = wall
			game.finale.player.finished.connect(func(): movie_natural_end = true;movie_end_time = wall)
		var pos: float = game.finale.player.stream_position
		if pos > 1.3: shot("Film-Approach")
		if pos > 7.5: shot("Film-Impact")
		if pos > 12.5: shot("Film-Vortex")
		if pos > 16.6: shot("Film-Mateo")
	elif game.mode == game.Mode.RESULTS:
		result_age += dt
		if not first_result:
			first_result = true
			saved_score = game.score
			saved_records = game.high_scores.duplicate(true)
			print("COMPLETED_CAPTURE_RESULTS natural_end=", movie_natural_end, " movie_seconds=", movie_end_time - movie_start_time, " score=", saved_score)
		if result_age > 0.25: shot("Results")
		if result_age > 3.0 and not replay_started:
			game.dodges.show_gallery();game.dodges._change_page(1)
		if replay_closed and result_age > 4.0:
			var passed: bool = movie_natural_end and replay_natural_end and game.result_title == "INTO THE VORTEX" and game.FINALE_FOOTAGE in game.footage_unlocked and game.score == saved_score and game.high_scores == saved_records and game.route.orbit_progress() == 1.0
			var report := {"version": ProjectSettings.get_setting("application/config/version"), "passed": passed, "natural_end": movie_natural_end, "replay_natural_end": replay_natural_end, "movie_start": movie_start_time, "movie_end": movie_end_time, "preview_end": preview_end_time, "score": saved_score, "probes": game.probes, "hull": game.health, "orbit": game.route.orbit_progress(), "wall": wall}
			var file := FileAccess.open(output_directory.path_join("completed-game-capture.json"), FileAccess.WRITE)
			file.store_string(JSON.stringify(report, "  "));file.close()
			print("COMPLETED_CAPTURE_DONE ", JSON.stringify(report))
			quit(0 if passed else 1)
	elif game.mode == game.Mode.CELEBRATION and not game.dodges.playing:
		gallery_age += dt
		shot("Earned-Finale")
		if not replay_started and gallery_age > 2.5:
			preview_end_time = wall
			replay_started = game.dodges.start_clip(14, true)
			if not replay_started:
				printerr("COMPLETED_CAPTURE_FAILED earned replay locked");quit(1);return false
			game.dodges.player.finished.connect(func(): replay_natural_end = true)
		elif replay_started:
			replay_closed = true
			game.dodges.close_gallery()
	if game.mode == game.Mode.CRASH or wall > 80.0:
		printerr("COMPLETED_CAPTURE_FAILED mode=", game.mode, " wall=", wall);quit(1)
	return false

func shot(label: String) -> void:
	if shots.has(label): return
	shots[label] = true
	call_deferred("save_frame", label)

func save_frame(label: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output_directory.path_join("Storm-Chaser-v0.11.0-" + label + ".png"))
