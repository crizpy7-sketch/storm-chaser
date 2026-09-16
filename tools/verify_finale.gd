extends SceneTree

var game
var checks := 0
var failures := 0
var film_index := 14

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

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1
	print("PASS: " if value else "FAIL: ", label)

func enter(probe_count: int = 3) -> void:
	game.start_chase()
	game.set_process(false)
	game.world.set_process(false)
	game.checkpoints.set_process(false)
	game.dodges.set_process(false)
	game.stage = 7;game.stage_seen = 7;game.elapsed = 210.0
	game.route.enter(7)
	game.speed = game.CRUISE_SPEEDS[7]
	game.score = 12345.0;game.probes = probe_count;game.health = 80.0
	game.save_checkpoint()
	game.finale.movies_enabled = true
	game.world._update_view(0)

func key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code;event.pressed = true
	return event

func pad(code: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = code;event.pressed = true
	return event

func run() -> void:
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"
	game = load("res://main.tscn").instantiate()
	game.settings_path = "user://finale-v011-isolated.cfg"
	root.add_child(game)
	await process_frame
	game.save_enabled = false
	game.footage_unlocked.clear()
	game.return_to_menu();game.dodges.show_gallery()
	media_check(game.dodges.streams.has(film_index), "approved finale is packaged for replay")
	check(not game.dodges.start_clip(film_index, true), "finale is locked before completing the lap")
	check(game.dodges.film_duration(film_index) == 18.0, "finale replay retains the full approved edit")
	game.dodges.close_gallery()
	enter()
	game.route.progress = game.route.ORBIT_APPROACH + game.route.ORBIT_RADIUS * TAU - 50.0
	game._simulate(0.001)
	check(game.mode == game.Mode.RUNNING and not game.finale.active, "finale cannot start before completing the actual tornado lap")
	game.route.progress = game.route.ORBIT_APPROACH + game.route.ORBIT_RADIUS * TAU
	game._simulate(0.001)
	var f = game.finale
	check(game.mode == game.Mode.VORTEX and f.film_playing, "completed lap starts the approved finale in the game")
	check(MediaPack.film_path(f.player.stream) == f.FILM_PATH, "finale selects the approved movie")
	check(absf(f.player.size.x / f.player.size.y - 910.0 / 512.0) < 0.0001, "film preserves truck and Mateo proportions")
	check(f.player.size.x <= 1280 and f.player.size.y <= 720, "entire film stays inside the viewport")
	check(f.player.material == null, "approved movie retains its accepted color grade")
	check(game.FINALE_FOOTAGE in game.footage_unlocked, "completing the lap earns final footage")
	check(game.engine_audio.stream_paused and game.music_audio.stream_paused and game.wind_audio.stream_paused, "game loops pause beneath the movie soundtrack")
	var mission := [game.elapsed, game.score, game.health, game.probes, game.route.progress]
	game._simulate(3);game.deploy_probe()
	check(mission == [game.elapsed, game.score, game.health, game.probes, game.route.progress], "final movie freezes mission, collision and probe scoring")
	f.age = 12.0;f.step(0.01)
	check(f.active and f.film_playing, "old eleven-second finale timer does not cut off the eighteen-second movie")
	check(game.score == mission[1] + 2000, "final transmission awards two thousand data once")
	game._unhandled_input(pad(JOY_BUTTON_START))
	check(game.mode == game.Mode.PAUSED and f.player.paused and not f.visible, "controller Start pauses film and exposes pause controls")
	var age: float = f.age
	f.step(20)
	check(f.age == age and game.score == mission[1] + 2000, "paused movie freezes its watchdog and rewards")
	# Browsing another movie while this one is paused must not resume it or its audio.
	var before_replay := [game.score, game.checkpoint.duplicate(true), game.high_scores.duplicate(true)]
	game.dodges.show_gallery();game.dodges._change_page(1)
	check(game.dodges.start_clip(film_index, true), "earned final movie can replay from the paused chase")
	game.dodges.film_age = 12.0;game.dodges._process(0.01)
	check(game.dodges.playing and not game.dodges.playback_failed, "replay watchdog allows the longer final film")
	game.dodges.finish_clip();game.dodges.close_gallery()
	check(game.mode == game.Mode.PAUSED and f.player.paused, "gallery returns to the paused finale")
	check(before_replay == [game.score, game.checkpoint, game.high_scores], "finale replay cannot duplicate score, records or checkpoint progress")
	check(game.engine_audio.stream_paused, "nested replay preserves the finale audio pause")
	game._unhandled_input(pad(JOY_BUTTON_START))
	check(game.mode == game.Mode.VORTEX and not f.player.paused and f.visible, "controller Start resumes the same movie")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.mode == game.Mode.PAUSED and f.player.paused, "focus loss pauses the movie instead of consuming the reward")
	game.resume_chase()
	f.player.finished.emit()
	check(game.mode == game.Mode.RESULTS and game.result_title == "INTO THE VORTEX", "movie completion opens the successful survey results")
	check(game.score == mission[1] + 2000 + 1600, "successful survey adds final data and remaining hull bonus exactly once")
	check(not game.can_retry_checkpoint(), "successful survey retires its checkpoint")
	check(not f.film_playing and f.player == null and f.finished, "completed player releases its decoder")
	check(not game.engine_audio.stream_paused and not game.music_audio.stream_paused, "movie completion restores game audio")
	var completed_score: float = game.score
	var completed_records: Array = game.high_scores.duplicate(true)
	f.complete();f.step(30)
	check(game.score == completed_score and game.high_scores == completed_records, "late completion and timer callbacks cannot duplicate rewards or records")
	game.dodges.show_gallery();game.dodges.start_clip(film_index, true)
	game.dodges.player.finished.emit();game.dodges.close_gallery()
	check(game.mode == game.Mode.RESULTS and game.score == completed_score and game.high_scores == completed_records, "replay returns to results without recording another expedition")
	for event in [key(KEY_SPACE), key(KEY_ENTER), pad(JOY_BUTTON_A), pad(JOY_BUTTON_B), pad(JOY_BUTTON_X)]:
		enter();f.begin();game._unhandled_input(event)
		check(game.mode == game.Mode.RESULTS and game.score == 15945, "keyboard/controller skip awards the earned ending exactly once")
	enter(2);f.begin();f.complete()
	check(game.result_title == "SURVEY INCOMPLETE" and game.score == 14345, "insufficient probes show incomplete survey without success hull bonus")
	check(game.can_retry_checkpoint(), "incomplete survey preserves the final checkpoint")
	game.retry_checkpoint()
	check(game.stage == 7 and game.probes == 2 and game.score == 12345 and game.route.progress == 0, "retry restores final level entrance without failed-attempt rewards")
	check(game.FINALE_FOOTAGE in game.footage_unlocked and not f.active, "earned film survives a clean checkpoint retry")
	enter();f.begin();f.player.stop();f.step(0.9)
	check(f.active and not f.film_playing and f.playback_failed, "stopped decoder safely falls back to the native ending")
	check(not game.engine_audio.stream_paused, "fallback restores live storm sound")
	f.step(f.LENGTH + 0.1)
	check(game.mode == game.Mode.RESULTS and game.score == 15945, "fallback completes without losing or repeating the final reward")
	enter();f.begin();f.stalled_for = 4.1;f.step(0.01)
	check(f.playback_failed and not f.film_playing, "stalled decoder cannot trap the player")
	f.complete()
	enter();f.movies_enabled = false;f.begin()
	check(f.active and not f.film_playing, "disabled movie uses the existing native finale")
	f.step(f.LENGTH + 0.1)
	check(game.mode == game.Mode.RESULTS, "native finale still reaches results")
	enter();f.begin();game.pause_chase();game.return_to_menu()
	check(game.mode == game.Mode.MENU and not f.active and f.player == null and not game.engine_audio.stream_paused, "return to base cleans up a paused decoder and restores sound")
	game.save_enabled = true
	game.footage_unlocked.assign([1, 7, 8])
	game.save_settings();game.footage_unlocked.clear();game._load_settings()
	check(8 in game.footage_unlocked and 1 in game.footage_unlocked and 7 in game.footage_unlocked and game.footage_unlocked.count(8) == 1, "earned final film survives a save and reload")
	game.footage_unlocked.clear();game.save_settings();game._load_settings()
	check(8 not in game.footage_unlocked, "an old level-seven checkpoint alone does not unlock the ending")
	game.save_enabled = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.settings_path))
	game.return_to_menu();game.dodges.show_gallery();game.dodges._change_page(1)
	var inside := true
	var return_focus := false
	for child in game.dodges.get_children():
		if child is Button:
			inside = inside and Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(child.get_rect())
			if child.text == "RETURN TO BASE": return_focus = child.focus_mode == Control.FOCUS_ALL
	check(inside and game.dodges.FILMS.size() == 15, "fifteen-film gallery fits across two pages")
	check(return_focus, "controller can focus the gallery return control")
	game.dodges.close_gallery()
	print("FINALE_TESTS ", checks, " checks; ", failures, " failures; ", skipped, " skipped")
	game.queue_free();await process_frame
	quit(0 if failures == 0 else 1)
