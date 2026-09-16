extends SceneTree

var game
var checks := 0
var failures := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1
	print("PASS: " if value else "FAIL: ", label)

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

func fresh(speed: float = 240.0) -> void:
	game.start_chase()
	game.speed = speed
	game.wind = 0.0
	game.puddle_timer = 100.0
	game.set_process(false)
	game.world.set_process(false)

func patch_at(lane: float, z: float = 0.0) -> Dictionary:
	game._spawn_puddle(lane)
	game.puddles.back().z = z
	game.puddles.back().kick = 1.0
	return game.puddles.back()

func run() -> void:
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"
	game = load("res://main.tscn").instantiate()
	game.settings_path = "user://driving-v080-test.cfg"
	root.add_child(game)
	await process_frame
	check(game.sfx.size() == 15 and game.sfx.values().all(func(p): return p.stream != null), "all gameplay sound players are created")
	media_check(game.sfx.values().all(func(p): return not p.stream.resource_path.is_empty()), "all gameplay sound effects load")
	media_check(game.sfx_variants.values().all(func(v): return v.size() >= 2), "one-shot effects rotate multiple ElevenLabs takes")
	media_check(game.music_audio.stream.get_length() > 30.0, "chase music asset loads")
	check(game.engine_audio.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "engine loop is ready")
	fresh()
	for i in range(100): game._spawn_puddle()
	check(game.puddles.all(func(p): return absf(p.lane) <= 0.68 and p.half_width <= 0.32), "puddles always leave a route around them")
	game.puddles.clear()
	patch_at(0.0)
	game._update_puddles(0.0)
	check(game.puddle_hits == 1 and game.aquaplane > 0.9 and game.glide_velocity > 1.0, "fast puddle hit breaks traction and kicks truck sideways")
	check(game.health == 100.0 and game.hits == 0, "water does not directly damage hull")
	check(game.world.spray.size() >= 24, "water hit emits a splash burst")
	game._update_puddles(0.0)
	check(game.puddle_hits == 1, "each puddle hits once")
	var fast_glide: float = game.glide_velocity
	fresh(68.0)
	game._hit_puddle(patch_at(0.0))
	check(game.glide_velocity < fast_glide * 0.6, "slowing before water softens the slide")
	fresh()
	game.tires = 0.63
	game._hit_puddle(patch_at(0.0))
	check(game.glide_velocity < fast_glide * 0.7, "grip upgrade reduces water kick")
	fresh()
	game.player_x = -0.82
	patch_at(0.65)
	game._update_puddles(0.0)
	check(game.puddle_hits == 0, "driving around puddle keeps traction")
	fresh()
	game._hit_puddle(patch_at(0.0))
	for i in range(30): game._update_driving(1.0 / 60.0)
	var coasting_glide: float = game.glide_velocity
	check(game.player_x > 0.15, "puddle causes actual lateral travel, not only a visual tilt")
	fresh()
	game._hit_puddle(patch_at(0.0))
	game.steer = -1.0
	game.braking = true
	for i in range(30): game._update_driving(1.0 / 60.0)
	check(absf(game.glide_velocity) < coasting_glide * 0.35 and game.aquaplane == 0, "brake and countersteer quickly restore grip")
	fresh()
	game.steer = 1.0
	for i in range(20): game._update_driving(1.0 / 60.0)
	game.world._update_view(0.0)
	check(absf(game.world.truck.rotation.y) > 0.025 and absf(game.world.truck.rotation.y) <= 0.13, "boost-speed fishtail uses a restrained heading")
	check(game.world.wheel_height_difference() < 0.0001 and game.world.truck.rotation.z == 0, "fishtail keeps truck upright on equal wheel heights")
	for i in range(600):
		game.steer = 1.0 if i % 80 < 40 else -1.0
		var previous_yaw: float = game.truck_yaw
		game._update_driving(1.0 / 60.0)
		if absf(game.truck_yaw - previous_yaw) > 0.025: failures += 1
	check(absf(game.player_x) <= 1.2 and absf(game.rear_slip) <= 1.4, "rapid steering remains bounded")
	fresh()
	game._hit_puddle(patch_at(0.0))
	game.mode = game.Mode.PAUSED
	var frozen: float = game.glide_velocity
	game._simulate(1.0)
	check(game.glide_velocity == frozen, "pause freezes slide physics")
	game.mode = game.Mode.UPGRADE
	game.stage = 1
	game.elapsed = 30.0
	game.choose_upgrade(1)
	check(game.puddles.is_empty() and game.aquaplane == 0 and game.glide_velocity == 0, "checkpoint clears water and momentum")
	game.checkpoints.complete()
	game._hit_puddle(patch_at(0.0))
	game.retry_checkpoint()
	check(game.puddles.is_empty() and game.glide_velocity == 0, "checkpoint retry starts with grip restored")
	game._hit_puddle(patch_at(0.0))
	game.return_to_menu()
	check(game.puddles.is_empty() and game.aquaplane == 0, "menu clears aquaplaning")
	game.haptics_enabled = false
	game.haptic(180)
	check(game.haptic_cooldown == 0, "vibration off prevents haptic output")
	print("DRIVING_TESTS ", checks, " checks; ", failures, " failures; ", skipped, " skipped")
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
