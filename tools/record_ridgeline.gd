extends SceneTree
# Capture the actual checkpoint decoder and its return to playable level six.
# Earlier driving is simulated under normal rules; no free score or hull.
var game
var wall := 0.0
var driving_time := 0.0
var movie_was_seen := false
var movie_finished := false
var shots: Dictionary = {}

func _initialize() -> void:
	call_deferred("start")

func start() -> void:
	game = load("res://main.tscn").instantiate()
	game.settings_path = "user://ridgeline-capture-isolated.cfg"
	root.add_child(game)
	game.demo = true;game.auto_dodges = false;game.save_enabled = false
	game.rng.seed = 72611
	game.start_chase()
	if not is_instance_valid(game.world.get("camera")):
		printerr("RIDGELINE_CAPTURE_FAILED world did not initialize");quit(1);return
	for frame in range(12000):
		if game.mode == game.Mode.UPGRADE:
			game.choose_upgrade(0 if game.health < 80 else 1)
			if game.stage == 5: break
			game.checkpoints.complete()
		if game.mode != game.Mode.RUNNING:
			printerr("RIDGELINE_CAPTURE_FAILED approach mode=",game.mode);quit(1);return
		if game.charge >= 100: game.deploy_probe()
		game._simulate(1.0 / 60.0)
	if game.stage != 5 or not game.checkpoints.film_playing:
		printerr("RIDGELINE_CAPTURE_FAILED checkpoint movie did not start");quit(1);return
	game.checkpoints.player.finished.connect(func(): movie_finished = true)
	game.world._update_view(0)
	print("RIDGELINE_MOVIE_START stage=",game.stage," score=",game.score," hull=",game.health)

func _process(dt: float) -> bool:
	if not is_instance_valid(game): return false
	wall += dt
	if game.mode == game.Mode.CHECKPOINT:
		if game.checkpoints.film_playing:
			movie_was_seen = true
			if game.checkpoints.player.stream_position > 2.0: shot("Film-Jump")
			if game.checkpoints.player.stream_position > 4.25: shot("Film-Landing")
		elif movie_was_seen:
			printerr("RIDGELINE_CAPTURE_FAILED decoder used fallback");quit(1)
	elif game.mode == game.Mode.RUNNING:
		driving_time += dt
		if game.route.air_height > 0.6: shot("Gameplay-Jump")
		if game.route.landings > 0: shot("Gameplay-Landing")
		if driving_time > 12.0: shot("Gameplay")
		if driving_time > 16.0:
			game.pause_chase();game.dodges.show_gallery();game.dodges._change_page(1)
			shot("Footage")
	elif game.mode == game.Mode.CELEBRATION and not game.dodges.playing:
		driving_time += dt
		if driving_time > 17.8:
			print("RIDGELINE_CAPTURE_COMPLETE movie_seen=",movie_was_seen," natural_end=",movie_finished," unlocked=",game.footage_unlocked," launches=",game.route.launches," landings=",game.route.landings," wall=",wall)
			quit(0 if movie_was_seen and movie_finished and 5 in game.footage_unlocked and game.route.launches > 0 and game.route.landings > 0 else 1)
	if wall > 31.0:
		printerr("RIDGELINE_CAPTURE_FAILED timeout");quit(1)
	return false

func shot(label: String) -> void:
	if shots.has(label): return
	shots[label] = true
	call_deferred("save_frame",label)

func save_frame(label: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	var destination := "../" if "--native-capture" in OS.get_cmdline_user_args() else "../exports/"
	root.get_texture().get_image().save_png(destination + "Storm-Chaser-v0.10.5-Ridgeline-" + label + ".png")
