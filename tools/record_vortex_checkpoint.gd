extends SceneTree
# Record the supplied checkpoint film, the complete playable tornado lap,
# the existing Godot suction finale with Mateo, and the earned gallery entry.
# Earlier stages use ordinary game rules; no free score, hull or probes.
var game
var wall := 0.0
var driving_time := 0.0
var results_time := 0.0
var gallery_time := 0.0
var movie_was_seen := false
var movie_finished := false
var vortex_was_seen := false
var results_were_seen := false
var max_orbit := 0.0
var shots: Dictionary = {}

func _initialize() -> void:
	call_deferred("start")

func start() -> void:
	game = load("res://main.tscn").instantiate()
	game.settings_path = "user://vortex-checkpoint-capture-isolated.cfg"
	root.add_child(game)
	game.demo = true;game.auto_dodges = false;game.save_enabled = false
	game.rng.seed = 72611
	game.start_chase()
	if not is_instance_valid(game.world.get("camera")):
		printerr("VORTEX_CHECKPOINT_CAPTURE_FAILED world did not initialize");quit(1);return
	for frame in range(16000):
		if game.mode == game.Mode.UPGRADE:
			game.choose_upgrade(0 if game.health < 80 else 1)
			if game.stage == 7: break
			game.checkpoints.complete()
		if game.mode != game.Mode.RUNNING:
			printerr("VORTEX_CHECKPOINT_CAPTURE_FAILED approach mode=",game.mode);quit(1);return
		if game.charge >= 100: game.deploy_probe()
		game._simulate(1.0 / 60.0)
	if game.stage != 7 or not game.checkpoints.film_playing:
		printerr("VORTEX_CHECKPOINT_CAPTURE_FAILED checkpoint movie did not start");quit(1);return
	game.checkpoints.player.finished.connect(func(): movie_finished = true)
	game.world._update_view(0)
	print("VORTEX_CHECKPOINT_MOVIE_START stage=",game.stage," score=",game.score," hull=",game.health)

func _process(dt: float) -> bool:
	if not is_instance_valid(game): return false
	wall += dt
	if game.mode == game.Mode.CHECKPOINT:
		if game.checkpoints.film_playing:
			movie_was_seen = true
			if game.checkpoints.player.stream_position > 1.0: shot("Film-Approach")
			if game.checkpoints.player.stream_position > 5.1: shot("Film-Lift")
		elif movie_was_seen:
			printerr("VORTEX_CHECKPOINT_CAPTURE_FAILED decoder used fallback");quit(1)
	elif game.mode == game.Mode.RUNNING:
		driving_time += dt
		max_orbit = maxf(max_orbit,game.route.orbit_progress())
		if driving_time > 2.0: shot("Gameplay-Approach")
		if max_orbit > 0.5: shot("Gameplay-Orbit")
	elif game.mode == game.Mode.VORTEX:
		vortex_was_seen = true
		max_orbit = maxf(max_orbit,game.route.orbit_progress())
		if game.finale.age > 4.0: shot("Mateo-Lift")
		if game.finale.age > 7.7: shot("Into-The-Vortex")
	elif game.mode == game.Mode.RESULTS:
		results_were_seen = true
		results_time += dt
		if results_time > 0.2: shot("Results")
		if results_time > 2.2:
			game.dodges.show_gallery();game.dodges._change_page(1)
			shot("Footage")
	elif game.mode == game.Mode.CELEBRATION and not game.dodges.playing:
		gallery_time += dt
		if gallery_time > 1.8:
			print("VORTEX_CHECKPOINT_CAPTURE_COMPLETE movie_seen=",movie_was_seen," natural_end=",movie_finished," unlocked=",game.footage_unlocked," vortex_seen=",vortex_was_seen," orbit=",max_orbit," results=",game.result_title," score=",game.score," wall=",wall)
			var passed: bool = movie_was_seen and movie_finished and 7 in game.footage_unlocked and vortex_was_seen and max_orbit == 1.0 and results_were_seen and game.result_title == "INTO THE VORTEX"
			quit(0 if passed else 1)
	if game.mode == game.Mode.CRASH or wall > 70.0:
		printerr("VORTEX_CHECKPOINT_CAPTURE_FAILED mode=",game.mode," wall=",wall);quit(1)
	return false

func shot(label: String) -> void:
	if shots.has(label): return
	shots[label] = true
	call_deferred("save_frame",label)

func save_frame(label: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	var destination := "../" if "--native-capture" in OS.get_cmdline_user_args() else "../exports/"
	root.get_texture().get_image().save_png(destination + "Storm-Chaser-v0.10.7-Vortex-Cinema-" + label + ".png")
