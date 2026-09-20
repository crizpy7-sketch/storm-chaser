extends SceneTree

var checks := 0
var failures := 0
var game

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", label)
	else:
		print("PASS: ", label)

# Media-pack presence checks are skipped (not passed) in trimmed copies; film
# orchestration still runs against a tiny placeholder film from tools/test_media.
const MediaPack = preload("res://scripts/media.gd")
var skipped := 0
func media_check(value: bool, label: String) -> void:
	if MediaPack.media_complete():
		check(value, label)
	else:
		skipped += 1
		print("SKIP: ", label, " (media pack not installed)")

func _initialize() -> void:
	call_deferred("run")

func enter_checkpoint(stage: int, choice: int = 1) -> void:
	game.start_chase()
	game.stage = stage
	game.elapsed = stage * game.STAGE_LENGTH
	game.mode = game.Mode.UPGRADE
	game.choose_upgrade(choice)
	game.set_process(false)
	game.checkpoints.set_process(false)

func quiet_road() -> void:
	game.spawn_timer = 99.0; game.pickup_timer = 99.0; game.puddle_timer = 99.0
	game.sky_timer = 99.0; game.lens_timer = 99.0; game.thunder_timer = 99.0

func verify_flag_resume() -> void:
	game.start_chase()
	game.elapsed = game.SAVE_SPAN - 0.01
	game.health = 50.0; game.score = 1000.0
	quiet_road()
	game._simulate(0.02)
	var flag: Dictionary = game.checkpoint.duplicate(true)
	check(flag.health == 65.0 and flag.score == 1500.0, "save flag banks its repair and data before taking the snapshot")
	for attempt in [1, 2]:
		game.health = 1.0; game.score += 900.0
		game.retry_checkpoint()
		check(game.health == flag.health and game.score == flag.score, "flag retry %d retains rewards and discards failed-attempt gains" % attempt)
		quiet_road()
		game._simulate(0.01)
		check(game.checkpoint == flag and game.health == flag.health and game.score < flag.score + 1.0, "flag retry %d cannot award the same repair or data twice" % attempt)

	for level in [3, 4, 5, 6, 7]:
		game.start_chase()
		game.stage = level; game.stage_seen = level
		game.elapsed = level * game.STAGE_LENGTH + game.SAVE_SPAN
		game.route.enter(level)
		game.route.progress = 300.0 if level == 7 else 1000.0
		game.route.grounded = false; game.route.air_height = 5.0; game.route.vertical_velocity = 4.0
		game.stage_entry_hits = 2; game.hits = 3
		game.save_checkpoint()
		var point: Dictionary = game.checkpoint.duplicate(true)
		check(game.valid_checkpoint(point), "level %d mid-stage course snapshot is valid" % (level + 1))
		game.retry_checkpoint()
		check(game.elapsed == point.elapsed and game.route.progress == point.route_progress, "level %d retry restores both time and road position" % (level + 1))
		check(game.route.grounded and game.route.air_height == 0.0 and game.route.vertical_velocity == 0.0 and is_equal_approx(game.route.body_y, game.route.height_at(game.route.progress)) and is_equal_approx(game.route.dirt, game.route.dirt_at(game.route.progress)), "level %d retry places the settled truck on the saved road surface" % (level + 1))
		check(game.stage_entry_hits == 2, "level %d retry preserves the career hit counter" % (level + 1))

	# The same field must survive the actual ConfigFile persistence path.
	game.save_enabled = true
	game.save_settings()
	game.checkpoint.clear()
	game._load_settings()
	game.save_enabled = false
	game.retry_checkpoint()
	check(game.stage == 7 and game.route.progress == 300.0, "saved road position survives a settings reload")
	var valid: Dictionary = game.checkpoint.duplicate(true)
	for invalid in [NAN, INF, -INF, -1.0, game.STAGE_LENGTH * game.TURBO_SPEED * 0.25 + 1.0, "300", null]:
		var broken: Dictionary = valid.duplicate(true)
		broken.route_progress = invalid
		check(not game.valid_checkpoint(broken), "invalid course distance is rejected: %s" % str(invalid))
	for valid_distance in [0, 300.0, game.STAGE_LENGTH * game.TURBO_SPEED * 0.25]:
		var bounded: Dictionary = valid.duplicate(true)
		bounded.route_progress = valid_distance
		check(game.valid_checkpoint(bounded), "finite course distance within the generated road is accepted: %s" % str(valid_distance))
	for version in [1, 2, 3]:
		var legacy: Dictionary = valid.duplicate(true)
		legacy.version = version
		legacy.stage = 2 if version == 1 else 4
		legacy.erase("route_progress")
		if version < 3: legacy.erase("elapsed")
		else: legacy.elapsed = 4.0 * game.STAGE_LENGTH + game.SAVE_SPAN
		check(game.valid_checkpoint(legacy), "version %d checkpoint without road position remains compatible" % version)
		game.checkpoint = legacy
		game.retry_checkpoint()
		var expected_elapsed: float = float(legacy.get("elapsed", legacy.stage * game.STAGE_LENGTH))
		check(game.elapsed == expected_elapsed and game.route.progress == 0.0, "version %d checkpoint retains its legacy entrance-position fallback" % version)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.settings_path))

func run() -> void:
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"
	game = load("res://main.tscn").instantiate()
	game.settings_path = "user://checkpoint-v0108-test.cfg"
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.checkpoints.set_process(false)
	verify_flag_resume()
	check(game.world.mateo != null, "recovered Mateo actor is present")
	media_check(game.dodges.streams.keys().filter(func(kind): return kind < 6).size() == 6, "all six existing dodge films load")
	for stage in [1, 2, 3, 4, 5, 6, 7]:
		enter_checkpoint(stage)
		var c = game.checkpoints
		check(c.active and c.film_playing and game.mode == game.Mode.CHECKPOINT, "checkpoint %d plays a movie" % stage)
		check(MediaPack.film_path(c.player.stream) == c.FILMS[stage], "checkpoint %d selects matching movie" % stage)
		check(game.engine_audio.stream_paused and game.music_audio.stream_paused, "game audio pauses under movie")
		check(game.debris.is_empty() and game.lens_marks.is_empty(), "road and lens hazards clear before movie")
		var score: float = game.score
		var health: float = game.health
		var elapsed: float = game.elapsed
		var probes: int = game.probes
		game._simulate(2.0)
		game.deploy_probe()
		check(game.elapsed == elapsed and game.score == score and game.health == health and game.probes == probes, "movie freezes mission and input scoring")
		c.age = 5.95
		c.step(0.1)
		check(c.active, "old scene timer does not end movie playback")
		c.player.finished.emit()
		check(game.mode == game.Mode.RUNNING and not c.active and not c.film_playing, "finished signal returns control once")
		check(game.can_retry_checkpoint() and int(game.checkpoint.stage) == stage, "finished movie saves matching checkpoint")
		check(not game.engine_audio.stream_paused and not game.music_audio.stream_paused, "game audio restores after movie")
		check(game.invulnerable == 2.0 and game.spawn_timer == 1.25, "return keeps safe-entry window")
		check(c.fade_left > 0.0, "movie completion fades gameplay in")
		var saved: Dictionary = game.checkpoint.duplicate(true)
		c.complete()
		check(game.checkpoint == saved, "duplicate finish cannot overwrite checkpoint")
		game.score += 900
		game.probes += 4
		game.health = 4
		game.retry_checkpoint()
		check(game.score == saved.score and game.probes == saved.probes and game.health == saved.health, "retry restores earned snapshot without failed-attempt gains")
		check(game.mode == game.Mode.RUNNING and not c.active and game.checkpoint_retry, "retry does not replay film or repeat upgrade")
		await process_frame
	enter_checkpoint(1)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	game._unhandled_input(key)
	check(game.mode == game.Mode.RUNNING and game.probes == 0, "keyboard skip does not fire a probe")
	enter_checkpoint(2)
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_A
	button.pressed = true
	game._unhandled_input(button)
	check(game.mode == game.Mode.RUNNING, "controller skip exits movie")
	enter_checkpoint(1)
	for child in game.checkpoints.get_children():
		if child is Button: child.pressed.emit()
	check(game.mode == game.Mode.RUNNING, "touch skip button exits movie")
	enter_checkpoint(1)
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.mode == game.Mode.PAUSED and game.can_retry_checkpoint(), "focus loss saves checkpoint and returns paused")
	check(not game.engine_audio.stream_paused, "focus loss restores audio pause state")
	enter_checkpoint(2)
	game.checkpoints.player.stop()
	game.checkpoints.step(1.0)
	check(game.checkpoints.active and not game.checkpoints.film_playing and is_instance_valid(game.checkpoints.building), "stopped video falls back to in-engine destruction")
	check(not game.music_audio.stream_paused, "fallback restores live audio")
	game.checkpoints.step(8.7)
	check(game.mode == game.Mode.RUNNING and game.can_retry_checkpoint(), "fallback still saves and returns control")
	game.checkpoints.movies_enabled = false
	enter_checkpoint(1)
	check(not game.checkpoints.film_playing and is_instance_valid(game.checkpoints.building), "disabled video route preserves original Mateo scene")
	game.checkpoints.complete()
	game.checkpoints.movies_enabled = true
	enter_checkpoint(1)
	game.checkpoints.age = 10.1
	game.checkpoints.step(0.01)
	check(not game.checkpoints.film_playing and game.checkpoints.active, "decoder watchdog uses live fallback")
	game.return_to_menu()
	check(not game.checkpoints.active and game.mode == game.Mode.MENU, "menu clears all checkpoint playback")
	for front in [3,4,5,6,7]:
		enter_checkpoint(front)
		game.checkpoints.step(3.0)
		check(game.checkpoints.film_playing and game.checkpoints.active, "route movie is not cut off by the short terrain preview timer")
		var movie_size: Vector2 = game.checkpoints.player.size
		check(absf(movie_size.x / movie_size.y - 898.0 / 512.0) < 0.0001, "route movie preserves original truck proportions")
		game.checkpoints.player.stop()
		game.checkpoints.step(0.1)
		check(game.checkpoints.route_preview and not game.checkpoints.film_playing and not is_instance_valid(game.checkpoints.building), "route decoder fallback previews the road without a warehouse")
		game.checkpoints.step(2.9)
		check(game.mode == game.Mode.RUNNING and game.checkpoint.stage == front, "route fallback safely saves and returns to driving")
		game.checkpoints.movies_enabled = false
		enter_checkpoint(front)
		check(not game.checkpoints.film_playing and game.checkpoints.route_preview, "disabled route movie retains the Mateo road preview")
		game.checkpoints.complete()
		game.checkpoints.movies_enabled = true
		game.return_to_menu();game.footage_unlocked.clear();game.dodges.show_gallery()
		check(game.dodges.streams.has(front+5) and not game.dodges.start_clip(front+5,true), "new gallery movie is present but locked before earning it")
		game.dodges._change_page(1)
		check(game.dodges.gallery_page == 1, "next page exposes the new route films")
		var within_screen := true
		for child in game.dodges.get_children():
			if child is Control and child.visible:
				within_screen = within_screen and child.position.y + child.size.y <= 720
		check(within_screen, "expanded gallery controls fit on screen")
		game.dodges.close_gallery()
		enter_checkpoint(front);game.checkpoints.complete();game.pause_chase()
		game.dodges.show_gallery()
		var replay_score: float = game.score
		var replay_save: Dictionary = game.checkpoint.duplicate(true)
		check(game.dodges.start_clip(front+5,true), "earned route movie replays from the footage gallery")
		game._simulate(3);game.dodges.finish_clip();game.dodges.close_gallery()
		check(game.mode == game.Mode.PAUSED and game.score == replay_score and game.checkpoint == replay_save, "route replay preserves progress and paused state")
		game.save_enabled = true;game.save_settings();game.footage_unlocked.clear()
		game._load_settings()
		check(front in game.footage_unlocked, "route footage survives save and reload")
		game.footage_unlocked.clear();game.save_settings();game._load_settings()
		check(front in game.footage_unlocked, "an existing reached checkpoint restores the new film unlock")
		game.save_enabled = false
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game.settings_path))

	# Complete the full eight-level route with the existing demo steering/probe rules.
	game.demo = true
	game.finale.movies_enabled = false
	game.rng.seed = 72611
	game.auto_dodges = false
	game.start_chase()
	var stages: Array[int] = []
	var flag_times: Array[float] = []
	var marks_seen := 0
	for frame in range(48000):
		if game.mode == game.Mode.UPGRADE:
			stages.append(game.stage)
			game.choose_upgrade(0 if game.health < 80 else 1)
			game.checkpoints.complete()
		if game.mode == game.Mode.RUNNING:
			if game.charge >= 100: game.deploy_probe()
			game._simulate(1.0 / 60.0)
			if game.saves_marked != marks_seen:
				marks_seen = game.saves_marked
				if game.message.begins_with("SAVE FLAG"): flag_times.append(game.elapsed)
		if game.mode==game.Mode.VORTEX: game.finale.step(1.0/60.0)
		if game.mode in [game.Mode.RESULTS, game.Mode.CRASH]: break
	check(stages == [1,2,3,4,5,6,7], "full run reaches seven checkpoints in order")
	# Two flags inside each of the seven timed stages. The vortex lap ends on
	# orbit progress rather than the clock and is far too short to reach one.
	var spans_per_stage: int = int(round(game.STAGE_LENGTH / game.SAVE_SPAN)) - 1
	check(flag_times.size() == 7 * spans_per_stage, "every timed stage records its mid-stage save flags")
	var rising := true
	for i in range(1, flag_times.size()):
		if flag_times[i] < flag_times[i-1]: rising = false
	check(rising, "save flags are recorded in order")
	check(flag_times.is_empty() or not is_zero_approx(fposmod(flag_times[0], game.STAGE_LENGTH)), "a flag never lands on a stage boundary, which belongs to the checkpoint")
	print("SAVE_FLAGS=", flag_times.size())
	check(game.mode == game.Mode.RESULTS and game.result_title == "INTO THE VORTEX", "recovered game remains winnable")
	check(game.probes >= 3 and game.score > 0, "full run earns valid probe/data score")
	check(not game.can_retry_checkpoint(), "victory retires checkpoint")
	check(not game.high_scores.is_empty(), "scoreboard records expedition")
	print("RUN_RESULT score=", game.score, " probes=", game.probes, " health=", game.health)
	print("CHECKPOINT_TESTS ", checks, " checks; ", failures, " failures; ", skipped, " skipped")
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
