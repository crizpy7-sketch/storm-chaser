extends SceneTree
# Capture the actual checkpoint decoder and its return to playable level four.
# Earlier driving is simulated under normal rules; no free score or hull.
var game
var wall := 0.0
var driving_time := 0.0
var movie_was_seen := false
var shots: Dictionary = {}

func _initialize() -> void:
	call_deferred("start")

func start() -> void:
	game = load("res://main.tscn").instantiate()
	game.settings_path = "user://crosswind-capture-isolated.cfg"
	root.add_child(game)
	game.demo = true;game.auto_dodges = false;game.save_enabled = false
	game.rng.seed = 72611
	game.start_chase()
	for frame in range(6500):
		if game.mode == game.Mode.UPGRADE:
			game.choose_upgrade(0 if game.health < 80 else 1)
			if game.stage == 3: break
			game.checkpoints.complete()
		if game.mode != game.Mode.RUNNING:
			printerr("CROSSWIND_CAPTURE_FAILED approach mode=",game.mode);quit(1);return
		if game.charge >= 100: game.deploy_probe()
		game._simulate(1.0 / 60.0)
	game.world._update_view(0)
	print("CROSSWIND_MOVIE_START stage=",game.stage," score=",game.score," hull=",game.health)

func _process(dt: float) -> bool:
	if not is_instance_valid(game): return false
	wall += dt
	if game.mode == game.Mode.CHECKPOINT:
		if game.checkpoints.film_playing:
			movie_was_seen = true
			if game.checkpoints.player.stream_position > 2.0: shot("Film")
		elif movie_was_seen:
			printerr("CROSSWIND_CAPTURE_FAILED decoder used fallback");quit(1)
	elif game.mode == game.Mode.RUNNING:
		driving_time += dt
		if driving_time > 2.0: shot("Gameplay")
		if driving_time > 6.0:
			game.pause_chase();game.dodges.show_gallery();game.dodges._change_page(1)
			shot("Footage")
	elif game.mode == game.Mode.CELEBRATION and not game.dodges.playing:
		driving_time += dt
		if driving_time > 7.8:
			print("CROSSWIND_CAPTURE_COMPLETE movie_seen=",movie_was_seen," unlocked=",game.footage_unlocked," wall=",wall)
			quit(0 if movie_was_seen and 3 in game.footage_unlocked else 1)
	if wall > 21.0:
		printerr("CROSSWIND_CAPTURE_FAILED timeout");quit(1)
	return false

func shot(label: String) -> void:
	if shots.has(label): return
	shots[label] = true
	call_deferred("save_frame",label)

func save_frame(label: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	var destination := "../" if "--native-capture" in OS.get_cmdline_user_args() else "../exports/"
	root.get_texture().get_image().save_png(destination + "Storm-Chaser-v0.10.1-Crosswind-" + label + ".png")
