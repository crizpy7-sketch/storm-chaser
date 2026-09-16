extends Node2D

enum Mode{MENU, RUNNING, PAUSED, UPGRADE, RESULTS, CELEBRATION, CRASH, CHECKPOINT, VORTEX, GARAGE}
const STAGE_LENGTH: = 30.0
const CRUISE_SPEEDS: = [146.0, 162.0, 178.0, 146.0, 122.0, 136.0, 148.0, 112.0]
const TURBO_SPEED: = 240.0
const DEBRIS_BASE_RATE: = 0.2
const DEBRIS_SPEED_RATE: = 0.0024
const STAGE_NAMES: = ["PRAIRIE APPROACH", "BARN BREAKOUT", "WAREHOUSE COLLAPSE", "CROSSWIND CURVES", "DIRT SHORTCUT", "RIDGELINE JUMPS", "WILD HILLS", "VORTEX RUN"]
const DEBRIS_MULTIPLIERS: = [1.0, 1.16, 1.32, 1.20, 1.10, 1.12, 1.20, 1.08]
const SAVE_PATH: = "user://storm_chaser.cfg"
const Media := preload("res://scripts/media.gd")
const STORM_FILM := "res://assets/cinematics/storm-film.ogv"
const Loadout := preload("res://scripts/loadout.gd")
const CHECKPOINT_FOOTAGE: = [1, 2, 3, 4, 5, 6, 7]
const FINALE_FOOTAGE := 8
var settings_path: = SAVE_PATH
var mode: int = Mode.MENU
var rng: = RandomNumberGenerator.new()
var clock: = 0.0
var elapsed: = 0.0
var stage: = 0
var stage_seen: = 0
var player_x: = 0.0
var steer: = 0.0
## The steering column itself. Raw input is a demand; a loaded truck's wheel
## has its own inertia and cannot snap from lock to lock, so this follows the
## demand at a bounded rate and is what the chassis actually reads.
var steer_column: = 0.0
var velocity_x: = 0.0
var rear_slip: = 0.0
var rear_slip_velocity: = 0.0
var truck_yaw: = 0.0
var skid_trails: Array[Dictionary] = []
var skid_timer: = 0.0
var aquaplane: = 0.0
var glide_velocity: = 0.0
var splash_pulse: = 0.0
var puddles: Array[Dictionary] = []
var puddle_timer: = 2.5
var puddle_hits: = 0
var water_rng: = RandomNumberGenerator.new()
var powertrain := preload("res://scripts/powertrain.gd").new()
var contacts := preload("res://scripts/truck_contacts.gd").new()
var motor_body: AudioStreamPlayer
var landing_audio: AudioStreamPlayer
var speed: = 0.0
var distance: = 900.0
var bend: = 0.0
var storm_offset: = 0.0
var wind: = 0.0
var health: = 100.0
var boost: = 100.0
var boost_max: = 100.0
var boosting: = false
var turbo_fx: = 0.0
var near_pulse: = 0.0
var near_side: = 1.0
var boost_locked: = false
var braking: = false
var charge: = 0.0
var probes: = 0
var score: = 0.0
var best: = 0
var high_scores: Array = []
var checkpoint: Dictionary = {}
var run_id: = ""
var checkpoint_retry: = false
var combo: = 0
var near_misses: = 0
var hits: = 0
var invulnerable: = 0.0
var shake: = 0.0
## Directional impact response. The frame is punched along the contact normal
## and banked, with a spring return, instead of being vibrated harder.
var cam_impulse: = Vector3.ZERO
var cam_impulse_velocity: = Vector3.ZERO
var cam_roll: = 0.0
var cam_roll_velocity: = 0.0
var yaw_kick: = 0.0
var yaw_kick_velocity: = 0.0
var flash: = 0.0
var lightning: = 0.0
var thunder_timer: = 6.0
var spawn_timer: = 2.0
var pickup_timer: = 8.0
var tires: = 1.0
var debris: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var sky_debris: Array[Dictionary] = []
var sky_timer: = 2.2
var sky_sequence: = 0
var flyby_pressure: = 0.0
var lens_projectiles: Array[Dictionary] = []
var lens_marks: Array[Dictionary] = []
var lens_timer: = 9.6
var lens_sequence: = 0
var lens_hits: = 0
var lens_kick: = 0.0
var message: = ""
var message_time: = 0.0
var muted: = false
var calm_fx: = false
var steering_assist := false
var relaxed_hazards := false
var light_graphics := false
var mateo_voice := true
var run_assisted := false
var footage_unlocked: Array[int] = []
var mateo_audio: AudioStreamPlayer
var mateo_caption := ""
var mateo_caption_time := 0.0
var mateo_cooldown := 0.0
var announced_landmark := -1
var cinematic_return := 0.0
var haptics_enabled: = true
var haptic_cooldown: = 0.0
var auto_dodges: = true
var touch_controls: = false
var touch_left: = false
var touch_right: = false
var touch_boost: = false
var touch_brake: = false
var result_title: = ""
var result_reason: = ""
var demo: = false
var demo_timer: = 0.0
var demo_boost_latched: = false
var world: Node2D
var hud: Control
var lens: Node2D
var wind_audio: AudioStreamPlayer
var engine_audio: AudioStreamPlayer
var music_audio: AudioStreamPlayer
var turbo_audio: AudioStreamPlayer
var skid_audio: AudioStreamPlayer
var sfx: Dictionary = {}
var sfx_variants: Dictionary = {}
var sfx_cursor: Dictionary = {}
var save_enabled: = true
var cinema_view: = false
var film_overlay: Control
var film_player: VideoStreamPlayer
var crashes: Node2D
var dodges: Control
var checkpoints: Control
var route
var finale: Control
var pause_resume_mode := Mode.RUNNING
## Mateo Garage loadout (cosmetic slots plus the optional chase setup).
var loadout: Dictionary = Loadout.default_loadout()
var garage: Control

func _ready() -> void :
	contacts.game=self
	rng.randomize()
	demo = "--demo" in OS.get_cmdline_user_args()
	save_enabled = not demo and not ("--test" in OS.get_cmdline_user_args())
	_setup_input()
	light_graphics = OS.has_feature("mobile")
	_load_settings()
	if "--test" in OS.get_cmdline_user_args(): auto_dodges = false
	touch_controls = OS.has_feature("mobile")
	route = preload("res://scripts/route.gd").new()
	route.game = self
	route.enter(0)
	world = Node2D.new()
	world.set_script(preload("res://scripts/world3d.gd"))
	world.game = self
	add_child(world)
	lens = Node2D.new()
	lens.set_script(preload("res://scripts/lens.gd"))
	lens.game = self
	lens.z_index = 10
	add_child(lens)
	dodges = Control.new()
	dodges.set_script(preload("res://scripts/dodge_films.gd"))
	dodges.game = self
	hud = Control.new()
	hud.set_script(preload("res://scripts/hud.gd"))
	hud.game = self
	hud.z_index = 20
	add_child(hud)
	garage = Control.new()
	garage.set_script(preload("res://scripts/garage.gd"))
	garage.game = self
	add_child(garage)
	world.truck.apply_loadout(loadout)
	powertrain.accel_factor = setup_factor("accel")
	add_child(dodges)
	_setup_audio()
	mateo_audio = AudioStreamPlayer.new()
	mateo_audio.volume_db = -7.0
	add_child(mateo_audio)
	crashes = Node2D.new()
	crashes.set_script(preload("res://scripts/crashes.gd"))
	crashes.game = self
	add_child(crashes)
	checkpoints = Control.new()
	checkpoints.set_script(preload("res://scripts/checkpoints.gd"))
	checkpoints.game = self
	add_child(checkpoints)
	finale = Control.new()
	finale.set_script(preload("res://scripts/vortex_finale.gd"))
	finale.game = self
	add_child(finale)
	if demo:
		rng.seed = 72611
		start_chase()

func _setup_input() -> void :
	var bindings: = {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "boost": [KEY_W, KEY_UP, KEY_SHIFT], "brake": [KEY_S, KEY_DOWN], "probe": [KEY_SPACE], "pause_game": [KEY_ESCAPE, KEY_P]}
	for action in bindings:
		if not InputMap.has_action(action): InputMap.add_action(action, 0.2)
		for key in bindings[action]:
			var event: = InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	var pads: = {"left": JOY_BUTTON_DPAD_LEFT, "right": JOY_BUTTON_DPAD_RIGHT, "boost": JOY_BUTTON_A, "brake": JOY_BUTTON_B, "probe": JOY_BUTTON_X, "pause_game": JOY_BUTTON_START}
	for action in pads:
		var event: = InputEventJoypadButton.new()
		event.button_index = pads[action]
		InputMap.action_add_event(action, event)

func _setup_audio() -> void :
	motor_body = _audio("motor_body", -30.0, true)
	landing_audio = _audio("landing_body", -9.0, false)
	wind_audio = _audio("wind", -22.0, true)
	engine_audio = _audio("engine", -20.0, true)
	music_audio = _audio("chase", -17.0, true)
	turbo_audio = _audio("turbo_loop", -50.0, true)
	skid_audio = _audio("skid", -50.0, true)
	for key in ["hit", "wood_hit", "metal_hit", "probe", "near", "thunder", "pickup", "click", "turbo_surge", "pass_left", "pass_right", "heavy_pass", "cow", "lens_hit", "splash"]:
		sfx[key] = _audio(key, -9.0, false)
		sfx_variants[key] = [sfx[key].stream]
		sfx_cursor[key] = 0
		for variation in range(2, 5):
			var path: String = "res://assets/audio/%s_v%d.wav" % [key, variation]
			if Media.available(path): sfx_variants[key].append(load(path))
	sfx.near.volume_db = -17.0
	sfx.pass_left.volume_db = -12.0
	sfx.pass_right.volume_db = -12.0
	sfx.heavy_pass.volume_db = -8.0
	sfx.cow.volume_db = -14.0
	sfx.lens_hit.volume_db = -7.0
	sfx.splash.volume_db = -5.0
	var limiter := AudioEffectLimiter.new()
	limiter.ceiling_db = -0.5
	if AudioServer.get_bus_effect_count(0) == 0: AudioServer.add_bus_effect(0, limiter)
	AudioServer.set_bus_mute(0, muted)

func _exit_tree() -> void :
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	sfx.clear()
	sfx_variants.clear()
	if route: route.game = null

func _audio(filename: String, db: float, looping: bool) -> AudioStreamPlayer:
	var p: = AudioStreamPlayer.new()
	p.stream = Media.audio("res://assets/audio/" + filename + ".wav")
	p.volume_db = db
	add_child(p)
	if looping:
		var clip := p.stream as AudioStreamWAV
		if clip != null:
			clip.loop_mode = AudioStreamWAV.LOOP_FORWARD
			clip.loop_begin = 0
			clip.loop_end = int(clip.get_length() * clip.mix_rate)
		p.play()
	return p

func play_sound(key: String) -> void :
	if not sfx.has(key): return
	var variants: Array = sfx_variants.get(key, [])
	if not variants.is_empty():
		sfx[key].stream = variants[int(sfx_cursor[key]) % variants.size()]
		sfx_cursor[key] += 1
	sfx[key].play()

func _load_settings() -> void :
	var config: = ConfigFile.new()
	high_scores.clear();checkpoint.clear()
	if config.load(settings_path) == OK:
		best = int(config.get_value("records", "best", 0))
		muted = bool(config.get_value("settings", "muted", false))
		calm_fx = bool(config.get_value("settings", "calm_fx", false))
		haptics_enabled = bool(config.get_value("settings", "haptics", true))
		steering_assist = bool(config.get_value("settings", "steering_assist", false))
		relaxed_hazards = bool(config.get_value("settings", "relaxed_hazards", false))
		light_graphics = bool(config.get_value("settings", "light_graphics", light_graphics))
		mateo_voice = bool(config.get_value("settings", "mateo_voice", true))
		footage_unlocked.clear()
		var films = config.get_value("records", "footage", [])
		if films is Array:
			for film in films:
				if film is int and (film in CHECKPOINT_FOOTAGE or film == FINALE_FOOTAGE) and film not in footage_unlocked: footage_unlocked.append(film)
		auto_dodges = bool(config.get_value("settings", "auto_dodges", true))
		loadout = Loadout.sanitize(config.get_value("garage", "loadout", {}))
		var rows = config.get_value("records", "scores", [])
		if rows is Array:
			for row in rows:
				if row is Dictionary and row.get("score", -1) is int and int(row.score) >= 0:
					high_scores.append(row)
			high_scores.sort_custom( func(a, b): return a.score > b.score)
			high_scores = high_scores.slice(0, 5)
		var saved = config.get_value("checkpoint", "snapshot", {})
		if saved is Dictionary and valid_checkpoint(saved):
			checkpoint = saved
			# A previous version checkpoint proves the earlier landmarks were reached.
			for reached in CHECKPOINT_FOOTAGE:
				if reached <= int(saved.stage) and reached not in footage_unlocked: footage_unlocked.append(reached)

func save_settings() -> void :
	if not save_enabled: return
	var config: = ConfigFile.new()
	config.set_value("records", "best", best)
	config.set_value("records", "footage", footage_unlocked)
	config.set_value("settings", "steering_assist", steering_assist)
	config.set_value("settings", "relaxed_hazards", relaxed_hazards)
	config.set_value("settings", "light_graphics", light_graphics)
	config.set_value("settings", "mateo_voice", mateo_voice)
	config.set_value("records", "scores", high_scores)
	config.set_value("checkpoint", "snapshot", checkpoint)
	config.set_value("settings", "muted", muted)
	config.set_value("settings", "calm_fx", calm_fx)
	config.set_value("settings", "haptics", haptics_enabled)
	config.set_value("settings", "auto_dodges", auto_dodges)
	config.set_value("garage", "loadout", loadout)
	config.save(settings_path)

func toggle_sound() -> void :
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	save_settings()

func toggle_calm() -> void :
	calm_fx = not calm_fx
	save_settings()
	hud.rebuild()

func toggle_haptics() -> void:
	haptics_enabled = not haptics_enabled
	if not haptics_enabled: Input.vibrate_handheld(0)
	save_settings()
	hud.rebuild()

func haptic(milliseconds: int, strength: float = 0.6) -> void:
	if not haptics_enabled or demo or haptic_cooldown > 0.0: return
	for pad in Input.get_connected_joypads():
		Input.start_joy_vibration(pad, strength * 0.3, strength, clampf(milliseconds / 1000.0, 0.01, 0.18))
	# Native Android exports need the VIBRATE permission; unsupported browsers ignore this.
	if OS.has_feature("mobile") or OS.has_feature("web"):
		Input.vibrate_handheld(clampi(milliseconds, 10, 180), clampf(strength, 0.0, 1.0))
		haptic_cooldown = 0.2

func start_chase(clear_checkpoint: bool = true) -> void :
	contacts.reset()
	crashes.reset()
	checkpoints.reset()
	finale.reset()
	route.enter(0)
	pause_resume_mode = Mode.RUNNING
	if clear_checkpoint:
		checkpoint.clear()
		save_settings()
	run_id = str(Time.get_unix_time_from_system()) + "-" + str(Time.get_ticks_usec())
	checkpoint_retry = false
	run_assisted = steering_assist or relaxed_hazards
	mateo_caption = ""; mateo_caption_time = 0.0; mateo_cooldown = 0.0
	announced_landmark = -1
	cinematic_return = 0.0
	if is_instance_valid(mateo_audio): mateo_audio.stop()
	if is_instance_valid(film_overlay): close_film()
	dodges.reset_for_run()
	mode = Mode.RUNNING
	elapsed = 0.0;stage = 0;stage_seen = 0;player_x = 0.0;velocity_x = 0.0
	steer = 0.0;rear_slip = 0.0;rear_slip_velocity = 0.0;skid_timer = 0.0
	skid_trails.clear()
	_reset_water()
	puddle_hits = 0
	water_rng.seed = rng.seed ^ 49317
	speed = 112.0;powertrain.reset(speed);distance = 900.0;health = 100.0;boost = 100.0;boost_max = 100.0
	boosting = false;braking = false;turbo_fx = 0.0;near_pulse = 0.0;near_side = 1.0
	demo_boost_latched = false
	charge = 0.0;probes = 0;score = 0.0;combo = 0;near_misses = 0;hits = 0
	invulnerable = 0.0;flash = 0.0;shake = 0.0;tires = 1.0
	spawn_timer = 0.85;pickup_timer = 7.0;thunder_timer = 6.0;boost_locked = false
	debris.clear();effects.clear();_clear_touch()
	sky_debris.clear();lens_projectiles.clear();lens_marks.clear()
	sky_timer = 5.0;sky_sequence = 0;flyby_pressure = 0.0
	lens_timer = 9.6;lens_sequence = 0;lens_hits = 0;lens_kick = 0.0
	world.reset_motion()
	notify("CHASE IS LIVE.  /  W TO FLOOR IT.  SPACE TO SEND PROBES.", 3.2)
	hud.rebuild()
	play_sound("click")

func _unhandled_input(event: InputEvent) -> void :
	if is_instance_valid(hud) and hud.settings_open:
		if event.is_action_pressed("pause_game"):
			hud.close_settings()
			get_viewport().set_input_as_handled()
		return
	if mode == Mode.CHECKPOINT:
		checkpoints.handle_input(event)
		return
	if mode == Mode.CRASH:
		crashes.handle_input(event)
		return
	if is_instance_valid(dodges) and dodges.visible:
		dodges.handle_input(event)
		return
	if is_instance_valid(film_overlay):
		if event is InputEventKey and event.pressed and event.physical_keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER]: close_film()
		elif event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_B, JOY_BUTTON_START]: close_film()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_M: toggle_sound()
		if event.physical_keycode == KEY_C and mode == Mode.RUNNING: cinema_view = not cinema_view
		if event.physical_keycode == KEY_T:
			touch_controls = not touch_controls
			hud.rebuild()
		if event.physical_keycode == KEY_F11:
			var full: = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
		if mode == Mode.MENU and event.physical_keycode == KEY_ENTER: start_chase()
		elif mode == Mode.RESULTS and event.physical_keycode == KEY_R:
			if can_retry_checkpoint(): retry_checkpoint()
			else: start_chase()
	if mode == Mode.GARAGE:
		garage.handle_input(event)
		return
	if mode == Mode.VORTEX:
		finale.handle_input(event)
		return
	if event.is_action_pressed("pause_game"):
		if mode in [Mode.RUNNING, Mode.VORTEX]: pause_chase()
		elif mode == Mode.PAUSED: resume_chase()
	if event.is_action_pressed("probe") and mode == Mode.RUNNING: deploy_probe()

func _notification(what: int) -> void :
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == Mode.CHECKPOINT and not demo:
		checkpoints.complete(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == Mode.CRASH and not demo:
		crashes.complete()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode in [Mode.RUNNING, Mode.VORTEX] and not demo:
		pause_chase()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == Mode.CELEBRATION and not demo and is_instance_valid(dodges):
		dodges.focus_lost()

func _clear_touch() -> void :
	touch_left = false;touch_right = false;touch_boost = false;touch_brake = false

func pause_chase() -> void :
	if mode not in [Mode.RUNNING,Mode.VORTEX]: return
	pause_resume_mode = mode
	dodges.cancel_pending()
	mode = Mode.PAUSED
	if pause_resume_mode == Mode.VORTEX: finale.set_paused(true)
	_clear_touch()
	hud.rebuild()

func resume_chase() -> void :
	if mode != Mode.PAUSED: return
	mode = pause_resume_mode
	if mode == Mode.VORTEX: finale.set_paused(false)
	hud.rebuild()

func return_to_menu() -> void :
	crashes.reset()
	checkpoints.reset()
	finale.reset()
	route.enter(0)
	pause_resume_mode = Mode.RUNNING
	dodges.reset_for_run()
	mode = Mode.MENU
	_reset_water()
	_clear_touch()
	hud.rebuild()

func has_storm_film() -> bool:
	return Media.available(STORM_FILM)

func show_film() -> void :
	if mode != Mode.MENU or is_instance_valid(film_overlay): return
	if not has_storm_film():
		notify("STORM FILM NOT INSTALLED", 2.0)
		return
	film_overlay = Control.new()
	film_overlay.size = Vector2(1280, 720)
	film_overlay.z_index = 100
	add_child(film_overlay)
	var black: = ColorRect.new()
	black.color = Color.BLACK
	black.size = Vector2(1280, 720)
	film_overlay.add_child(black)
	film_player = VideoStreamPlayer.new()
	film_player.stream = Media.video(STORM_FILM)
	film_player.expand = true
	film_player.size = Vector2(1280, 720)
	film_overlay.add_child(film_player)
	film_player.finished.connect(close_film)
	var back: = Button.new()
	back.text = "HIGGSFIELD CINEMATIC  /  RETURN TO GAME  [ESC]"
	back.position = Vector2(360, 667)
	back.size = Vector2(560, 35)
	back.pressed.connect(close_film)
	film_overlay.add_child(back)
	back.grab_focus()
	film_player.play()

func close_film() -> void :
	if not is_instance_valid(film_overlay): return
	film_player.stop()
	film_player.stream = null
	film_overlay.queue_free()
	film_overlay = null
	film_player = null
	hud.rebuild()

func choose_upgrade(choice: int) -> void :
	if mode != Mode.UPGRADE: return
	if choice == 0:
		health = minf(100.0, health + 40.0)
		notify("FIELD REPAIR  /  +40 HULL", 3.0)
	elif choice == 1:
		tires *= 0.63
		notify("GRIP UPGRADE  /  LESS WIND DRIFT", 3.0)
	else:
		boost_max += 30.0
		boost = boost_max
		notify("TURBO UPGRADE  /  +30 BOOST", 3.0)
	stage_seen = stage
	_clear_touch()
	play_sound("pickup")
	route.enter(stage)
	world.reset_motion()
	checkpoints.begin(stage)

func _process(delta: float) -> void :
	var dt: = minf(delta, 0.05)
	clock += dt
	if demo:
		demo_timer += dt
		if mode == Mode.UPGRADE: choose_upgrade(0 if health < 80 else 1)
		if mode == Mode.RUNNING and charge >= 100.0: deploy_probe()
	if mode == Mode.RUNNING:
		var hold := 1.0
		if crashes.hit_stop > 0.0:
			var u: float = 1.0 - crashes.hit_stop / crashes.hit_stop_span
			hold = lerpf(0.05, 1.0, u * u)
		_simulate(dt * hold)
	if mode == Mode.VORTEX: finale.step(delta)
	dodges.dispatch_pending()
	if is_instance_valid(engine_audio):
		var wear: float = clampf((55.0-health)/55.0,0,1)
		engine_audio.pitch_scale = (0.62 + powertrain.rpm / 6600.0)*(1.0+wear*sin(elapsed*23.0)*0.023)
		engine_audio.volume_db = (-17.0 + powertrain.load * 6.0 + wear * sin(elapsed*15.0)*0.7) if mode == Mode.RUNNING else -45.0
		motor_body.pitch_scale = 0.65 + powertrain.rpm / 4800.0
		motor_body.volume_db = lerpf(-31.0, -19.0, powertrain.load) if mode == Mode.RUNNING else -60.0
		music_audio.volume_db = -60.0 if is_instance_valid(film_overlay) else ((-22.0 if is_breathing() else -17.0) - (4.0 if mateo_caption_time>0 else 0.0) if mode == Mode.RUNNING else -26.0)
		wind_audio.volume_db = -60.0 if is_instance_valid(film_overlay) else ((-21.0 + speed / 55.0) if mode == Mode.RUNNING else -34.0)
		turbo_audio.volume_db = lerpf(-48.0, -15.0, turbo_fx) if mode == Mode.RUNNING else -50.0
		turbo_audio.pitch_scale = 0.9 + speed / 400.0
		var slide_sound: = clampf(absf(rear_slip) * 0.8 + absf(rear_slip_velocity) * 0.18, 0.0, 1.0)
		slide_sound=maxf(slide_sound,route.shortcut_slide*0.95)
		skid_audio.volume_db = lerpf(-48.0, -19.0, slide_sound) if mode == Mode.RUNNING else -50.0
		skid_audio.pitch_scale = 0.85 + speed / 600.0
	if mode == Mode.VORTEX:
		wind_audio.volume_db = -11.0
		music_audio.volume_db = -13.0
		engine_audio.volume_db = -18.0
	if is_instance_valid(mateo_audio): mateo_audio.stream_paused = mode != Mode.RUNNING
	world.queue_redraw()
	lens.queue_redraw()
	hud.queue_redraw()

func _simulate(dt: float) -> void :
	if mode != Mode.RUNNING: return
	contacts.begin_step()
	elapsed += dt
	cinematic_return = maxf(0.0,cinematic_return-dt*0.7)
	mateo_caption_time = maxf(0.0,mateo_caption_time-dt)
	mateo_cooldown = maxf(0.0,mateo_cooldown-dt)
	stage = mini(7, int(elapsed / STAGE_LENGTH))
	run_assisted = run_assisted or steering_assist or relaxed_hazards
	if stage < 2 and fposmod(elapsed, STAGE_LENGTH) >= 23.0 and announced_landmark != stage:
		announced_landmark = stage
		notify(("SILO COUNTY" if stage == 0 else "FREIGHT DISTRICT") + " AHEAD  /  NEW FOOTAGE AT CHECKPOINT", 4.0)
	if stage > stage_seen:
		elapsed = stage * STAGE_LENGTH
		mode = Mode.UPGRADE
		dodges.cancel_pending()
		_clear_touch()
		hud.rebuild()
		return
	bend = sin(elapsed * 0.17) * 0.73 + sin(elapsed * 0.35) * 0.16
	storm_offset = sin(elapsed * 0.155 + 0.6) * 0.34
	wind = (sin(elapsed * 1.12) * 0.09 + sin(elapsed * 0.37) * 0.1) * (1.0 + mini(stage, 3) * 0.45)
	steer = Input.get_axis("left", "right")
	var pads: = Input.get_connected_joypads()
	if not pads.is_empty():
		var analog: = Input.get_joy_axis(pads[0], JOY_AXIS_LEFT_X)
		if absf(analog) > 0.18: steer = analog
	if touch_left: steer -= 1.0
	if touch_right: steer += 1.0
	steer = clampf(steer, -1.0, 1.0)
	braking = Input.is_action_pressed("brake") or touch_brake
	var wants_boost: = Input.is_action_pressed("boost") or touch_boost
	if demo:
		var safest: = _demo_target()
		steer = clampf((safest - player_x) * 6.5 - glide_velocity * 0.75 - route.drift * 0.85, -1.0, 1.0)
		if boost <= 18.0 or distance < 670.0: demo_boost_latched = false
		elif boost > 70.0 and distance > 820.0: demo_boost_latched = true
		wants_boost = demo_boost_latched
		braking = route.brake_advised() if route.active else distance < 550.0
		if route.active: wants_boost = false
	if boost_locked and ( not wants_boost or boost >= 28.0): boost_locked = false
	var was_boosting: = boosting
	boosting = wants_boost and not braking and boost > 0.0 and not boost_locked
	if boosting and not was_boosting: play_sound("turbo_surge")
	turbo_fx = move_toward(turbo_fx, 1.0 if boosting else 0.0, dt * (5.5 if boosting else 3.0))
	near_pulse = maxf(0.0, near_pulse - dt * 3.2)
	var target_speed: float = CRUISE_SPEEDS[stage]
	if boosting: target_speed = TURBO_SPEED
	if braking: target_speed = 68.0
	if absf(player_x) > 1.03: target_speed *= 0.65
	speed = powertrain.step(dt, speed, target_speed, boosting, braking, route.grounded, route.dirt, route.grade(route.progress) if route.active else 0.0)
	if boosting:
		boost = maxf(0.0, boost - dt * 22.0 * setup_factor("boost_drain"))
		if boost <= 0.0: boost_locked = true
	else: boost = minf(boost_max, boost + dt * 14.0 * setup_factor("boost_recharge"))
	route.step(dt)
	_update_driving(dt)
	_update_puddles(dt)
	if route.active:
		var target_distance: float = [0,0,0,820,650,490,320,180][stage]
		distance = move_toward(distance,target_distance,dt*24.0)
	else:
		distance += ((CRUISE_SPEEDS[stage] + 16.0) - speed) * 0.4 * dt
	distance = maxf(125.0, distance)
	invulnerable = maxf(0.0, invulnerable - dt)
	shake = maxf(0.0, shake - dt * 22.0)
	var impulse_left := dt
	while impulse_left > 0.000001:
		var ih := minf(impulse_left, 1.0 / 120.0)
		impulse_left -= ih
		cam_impulse_velocity += (-cam_impulse * 230.0 - cam_impulse_velocity * 24.0) * ih
		cam_impulse += cam_impulse_velocity * ih
		cam_roll_velocity += (-cam_roll * 230.0 - cam_roll_velocity * 24.0) * ih
		cam_roll += cam_roll_velocity * ih
		yaw_kick_velocity += (-yaw_kick * 150.0 - yaw_kick_velocity * 17.0) * ih
		yaw_kick += yaw_kick_velocity * ih
	cam_impulse = cam_impulse.limit_length(0.22)
	cam_roll = clampf(cam_roll, -0.055, 0.055)
	yaw_kick = clampf(yaw_kick, -0.16, 0.16)
	flash = maxf(0.0, flash - dt * 3.0)
	lightning = maxf(0.0, lightning - dt * 2.5)
	message_time = maxf(0.0, message_time - dt)
	if distance < 300.0 and not route.active:
		health -= dt * 6.0 * setup_factor("damage")
		if message_time < 0.2: notify("TOO CLOSE!  /  BRAKE TO BACK AWAY", 1.0)
	if distance > 1850.0:
		finish(false, "The tornado escaped radar range. Use boost to close the gap.")
		return
	if in_sampling_range():
		charge = minf(100.0, charge + dt * 7.5)
		score += dt * (20.0 + stage * 10.0)
	else: score += dt * 5.0
	spawn_timer -= dt
	if spawn_timer <= 0.0 and not is_breathing():
		_spawn_wave()
		spawn_timer = (rng.randf_range(1.50, 1.90) if route.active else rng.randf_range(1.22, 1.52) - stage * 0.10) * (1.18 if relaxed_hazards else 1.0)
	pickup_timer -= dt
	if pickup_timer <= 0.0:
		_spawn_item(4, rng.randf_range(-0.8, 0.8))
		pickup_timer = rng.randf_range(8.0, 10.0)
	thunder_timer -= dt
	if thunder_timer <= 0.0:
		lightning = 0.32
		play_sound("thunder")
		thunder_timer = rng.randf_range(8.0, 13.0)
	_update_debris(dt)
	_update_effects(dt)
	_update_cinematics(dt)
	if health <= 0.0:
		health = 0.0
		finish(false, "The truck took too much damage. Watch the shadows and leave room to dodge.")
	elif stage == 7 and route.orbit_progress() >= 1.0:
		finale.begin()

func in_sampling_range() -> bool:
	return distance >= (150.0 if route.active else 450.0) and distance <= 1150.0

func _update_fishtail(dt: float) -> void :
	var target: float = clampf(-steer_column * speed / 240.0 * 0.58 + glide_velocity * 0.36 + wind * 0.4, -0.7, 0.7)
	if braking: target *= 0.4
	# Corner momentum drives the rear pose, with the original rigid truck yaw cap.
	target=lerpf(target,-0.78,route.shortcut_slide)
	rear_slip_velocity += (target - rear_slip) * (36.0 if route.grounded else 7.5) * dt
	rear_slip_velocity *= exp(-dt * (12.0 if braking else 9.0))
	rear_slip = clampf(rear_slip + rear_slip_velocity * dt, -0.8, 0.8)
	# Lateral travel carries the glide; keep the original truck silhouette and heading restrained.
	var heading: float = clampf(rear_slip * 0.11 - velocity_x * 0.018-route.shortcut_slide*0.034, -0.13, 0.13)
	truck_yaw = lerpf(truck_yaw, heading, 1.0 - exp(-dt * 6.0))
	for trail in skid_trails: trail.age += dt
	skid_trails = skid_trails.filter( func(trail): return trail.age < 0.52)
	skid_timer -= dt
	if skid_timer <= 0.0 and route.grounded:
		skid_timer = 0.025
		skid_trails.append({"lane": player_x, "age": 0.0, "strength": clampf(absf(rear_slip) + absf(rear_slip_velocity) * 0.15+route.shortcut_slide*0.4, 0.0, 1.0), "yaw":truck_yaw,"course":route.progress})

func _reset_water() -> void:
	puddles.clear()
	steer_column = 0.0
	cam_impulse = Vector3.ZERO; cam_impulse_velocity = Vector3.ZERO
	cam_roll = 0.0; cam_roll_velocity = 0.0
	yaw_kick = 0.0; yaw_kick_velocity = 0.0
	aquaplane = 0.0
	glide_velocity = 0.0
	truck_yaw = 0.0
	splash_pulse = 0.0
	puddle_timer = 2.5
	haptic_cooldown = 0.0

func road_steering_limit() -> float:
	# Normalized lane positions locate the truck CENTER. Reserve body width and
	# clearance before the pavement edge; retain the wider off-road envelope.
	var road_width: float = route.width() if route.active else 14.0
	var lane_unit: float = route.lane_scale() if route.active else 5.8
	var paved_limit: float = (road_width * 0.5 - 1.85 - 0.40) / lane_unit
	return lerpf(paved_limit,1.2,route.dirt if route.active else 0.0)

func _update_driving(dt: float) -> void:
	var countersteering: bool = steer * glide_velocity < -0.08
	aquaplane = move_toward(aquaplane, 0.0, dt * (0.7 + (0.75 if steering_assist else 0.0) + (1.7 if braking else 0.0) + (0.35 if countersteering else 0.0)) * setup_factor("water_grip"))
	var recovery: float = 0.8 + (1.8 if steering_assist else 0.0) + (1.0 - aquaplane) * 2.1 + (2.0 if countersteering else 0.0) + (3.4 if braking else 0.0)
	glide_velocity *= exp(-dt * recovery)
	splash_pulse = maxf(0.0, splash_pulse - dt * 2.8)
	haptic_cooldown = maxf(0.0, haptic_cooldown - dt)
	# The column winds on at a bounded rate that tightens with speed. Caster
	# self-centres, so unwinding and reversing come back faster than new lock.
	var column_rate: float = lerpf(8.2, 4.4, clampf((speed - 90.0) / 150.0, 0.0, 1.0))
	if absf(steer) < absf(steer_column) or steer * steer_column < 0.0: column_rate *= 1.75
	if steering_assist: column_rate *= 1.4
	steer_column = move_toward(steer_column, steer, column_rate * dt)
	var response: float = 14.0 if braking else lerpf(10.0, 6.0 if steering_assist else 3.8, aquaplane)
	# Mass resists a change of direction more the faster it is already moving.
	if not steering_assist: response *= lerpf(1.0, 0.72, clampf((speed - 90.0) / 150.0, 0.0, 1.0))
	response *= route.traction
	var road_limit: float = road_steering_limit()
	var edge_weight: float = smoothstep(road_limit-0.22,road_limit,absf(player_x))
	var steering_gain: float = lerpf(1.0,0.18,edge_weight) if steer_column*player_x>0.0 else 1.0
	# Lateral authority falls with speed: the truck gets harder to place, not easier.
	var authority: float = lerpf(2.55, 2.02, clampf((speed - 120.0) / 120.0, 0.0, 1.0))
	if route.grounded:
		velocity_x = lerpf(velocity_x, steer_column * steering_gain * authority, 1.0 - exp(-dt * response))
	else:
		# Airborne there is nothing to push against. Momentum carries and the
		# wheels only nudge; letting go of the stick must not cancel a launch.
		velocity_x = clampf(velocity_x + steer_column * 1.25 * dt, -2.6, 2.6)
	_update_fishtail(dt)
	player_x = clampf(player_x + (velocity_x + glide_velocity + wind * tires + rear_slip * 0.1 + route.drift) * dt, -road_limit, road_limit)
	if steering_assist and absf(steer_column) < 0.15 and absf(player_x) > 0.94:
		player_x = move_toward(player_x, signf(player_x)*0.90, dt*0.16)
	# Shed outward momentum at the shoulder so countersteering always brings the truck back.
	if absf(player_x) >= road_limit-0.001:
		if velocity_x * player_x > 0.0: velocity_x *= exp(-dt * 10.0)
		if glide_velocity * player_x > 0.0: glide_velocity *= exp(-dt * 12.0)

func _spawn_puddle(lane: float = 99.0) -> void:
	var selected: float = water_rng.randf_range(-0.68, 0.68) if lane > 2.0 else clampf(lane, -0.68, 0.68)
	puddles.append({"lane": selected, "z": -92.0, "half_width": water_rng.randf_range(0.24, 0.32), "length": water_rng.randf_range(6.5, 9.5), "phase": water_rng.randf() * TAU, "kick": -1.0 if water_rng.randf() < 0.5 else 1.0, "hit": false})

func _update_puddles(dt: float) -> void:
	puddle_timer -= dt
	if puddle_timer <= 0.0 and not is_breathing():
		_spawn_puddle()
		puddle_timer = water_rng.randf_range(4.2, 5.8) - mini(stage, 2) * 0.6
	for p in puddles:
		p.z += dt * speed * 0.25
		if p.hit: continue
		var dx: float = maxf(0.0, absf(player_x - p.lane) - 0.16) / p.half_width
		var dz: float = maxf(0.0, absf(p.z) - 1.6) / (p.length * 0.5)
		if dx * dx + dz * dz < 1.0:
			p.hit = true
			_hit_puddle(p)
	puddles = puddles.filter(func(p): return p.z < 16.0)

func _hit_puddle(p: Dictionary) -> void:
	if not route.grounded: return
	var intensity: float = clampf((speed - 50.0) / 190.0, 0.1, 1.0)
	var offset: float = player_x - p.lane
	var side: float = signf(offset) if absf(offset) > 0.055 else (signf(velocity_x) if absf(velocity_x) > 0.15 else p.kick)
	if absf(player_x) > 0.82: side = -signf(player_x)
	aquaplane = maxf(aquaplane, (0.48 + intensity * 0.5) * sqrt(tires))
	glide_velocity = clampf(glide_velocity + side * (0.55 + intensity * 0.65) * tires * (2.0 - setup_factor("water_grip")), -1.45, 1.45)
	rear_slip_velocity += side * (0.75 + intensity * 0.65) * tires
	splash_pulse = 1.0
	puddle_hits += 1
	world.splash_burst(intensity)
	play_sound("splash")
	haptic(85, 0.65)
	notify("AQUAPLANE  /  COUNTERSTEER + TAP BRAKE", 1.8)

func _spawn_sky_piece(kind: int, side: float) -> void :

	sky_debris.append({"kind": kind, "age": 0.0, "duration": 4.1 if kind == 0 else 3.35, "side": side, "origin": 640.0 + storm_offset * 400.0, "whooshed": false, "start_x": player_x, "end_x": player_x * 5.8 + side * 5.0, "warned": false, "start_hits": hits, "movement": 0.0, "steered": false, "celebrated": false})

func _launch_lens_piece() -> void :
	var hit_x: = 415.0 if lens_sequence % 2 == 0 else 895.0
	lens_sequence += 1
	lens_projectiles.append({"age": 0.0, "duration": 0.86, "target": Vector2(hit_x, 362.0), "origin": Vector2(640.0 + storm_offset * 370.0, 274.0), "hit": false})

func _strike_lens(point: Vector2) -> void :
	lens_hits += 1
	lens_kick = 1.0
	lens_marks.append({"point": point, "age": 0.0, "duration": 3.6, "seed": lens_hits})
	# A bolt on the glass previously lit the scene less than a horizon rumble.
	var strike_side: float = signf(point.x - 640.0)
	lightning = maxf(lightning, 0.95)
	flash = maxf(flash, 0.75)
	cam_impulse_velocity += Vector3(strike_side * 2.1, -1.4, 0.9)
	cam_roll_velocity -= strike_side * 1.15
	glide_velocity = clampf(glide_velocity + strike_side * 0.34, -1.8, 1.8)
	speed = maxf(40.0, speed - 7.0)
	haptic(165, 1.0)
	play_sound("thunder")
	play_sound("lens_hit")
	notify("CAMERA STRIKE  /  KEEP YOUR LINE", 1.35)

func _update_cinematics(dt: float) -> void :
	sky_timer -= dt
	if sky_timer <= 0.0 and not is_breathing():
		var kind: = sky_sequence % 2
		_spawn_sky_piece(kind, -1.0 if sky_sequence % 4 in [0, 3] else 1.0)
		sky_sequence += 1
		sky_timer = 10.0 if kind == 0 else 13.0
	var pressure: = 0.0
	for piece in sky_debris:
		piece.age += dt
		piece.movement = maxf(piece.movement, absf(player_x - float(piece.start_x)))
		piece.steered = piece.steered or absf(steer) > 0.35
		var u: float = piece.age / piece.duration
		pressure = maxf(pressure, sin(clampf(u, 0.0, 1.0) * PI) * 0.12)
		if not piece.get("warned", false) and u >= 0.17:
			piece.warned = true
			play_sound("pass_left" if piece.side < 0 else "pass_right")
		if not piece.whooshed and u >= 0.52:
			piece.whooshed = true
			play_sound("heavy_pass" if piece.kind == 0 else "cow")
		if piece.kind==0 and not piece.get("ruptured",false) and u>=.36:
			piece.ruptured=true
			play_sound("metal_hit")
			_shed_semi_roof(piece)
		if not piece.celebrated and u >= 0.9:
			piece.celebrated = true
			# Background flybys no longer award pretend near misses.
	sky_debris = sky_debris.filter( func(piece): return piece.age < piece.duration)
	flyby_pressure = lerpf(flyby_pressure, pressure, 1.0 - exp( - dt * 5.0))
	lens_timer -= dt
	if lens_timer <= 0.0 and not is_breathing():
		_launch_lens_piece()
		lens_timer = 20.0
	lens_kick = maxf(0.0, lens_kick - dt * 5.5)
	for mark in lens_marks: mark.age += dt
	lens_marks = lens_marks.filter( func(mark): return mark.age < mark.duration)
	for projectile in lens_projectiles:
		projectile.age += dt
		if not projectile.hit and projectile.age >= projectile.duration:
			projectile.hit = true
			_strike_lens(projectile.target)
	lens_projectiles = lens_projectiles.filter( func(projectile): return not projectile.hit)

func deploy_probe() -> void :
	if mode != Mode.RUNNING: return
	if not in_sampling_range():
		notify("MOVE INTO TRACKING RANGE  /  450-1150 M", 2.2)
		return
	if charge < 99.99:
		notify("PROBE CHARGING  /  %d%%" % int(charge), 1.5)
		return
	charge = 0.0
	probes += 1
	score += 1500.0
	effects.append({"type": "probe", "x": player_x, "z": 1.0, "life": 1.8, "max_life": 1.8})
	notify("PROBE %02d TRANSMITTING  /  +1,500 DATA" % probes, 3.0)
	play_sound("probe")

func _spawn_item(kind: int, lane: float, start: float = 0.0) -> void :
	debris.append({"kind": kind, "theme": (3 if stage >= 4 else mini(stage,2)) if kind < 4 else 0, "lane": lane, "z": start, "spin": rng.randf_range(-4.4, 4.4), "angle": rng.randf_range(-0.4, 0.4), "checked": false, "whooshed": false, "phase": rng.randf() * TAU, "drift": rng.randf_range(-0.065, 0.065) * stage})

func _spawn_wave() -> void :
	var lanes: = [-0.76, -0.25, 0.25, 0.76]
	var first: = rng.randi_range(0, 3)
	_spawn_item(rng.randi_range(0, 3), lanes[first])
	if stage > 0 and rng.randf() < (0.25 if route.active else 0.45):

		var second: = first + 1 if first < 3 else 2
		_spawn_item(rng.randi_range(0, 3), lanes[second], -0.06)

func debris_rate() -> float:
	return (DEBRIS_BASE_RATE + speed * DEBRIS_SPEED_RATE) * DEBRIS_MULTIPLIERS[stage] * (0.78 if relaxed_hazards else 1.0)

func _shed_semi_roof(piece: Dictionary) -> void:
	if piece.get("shed",false):return
	piece.shed=true
	var u: float=clampf(piece.age/piece.duration,0,1)
	var part: Node3D=world.semi_wreck_template.get_node("RoofSheet00")
	var pose: Transform3D=world.sky_transform(piece)*preload("res://scripts/semi_wreck.gd").part_transform(part,u)
	_spawn_item(3,clampf(float(piece.get("start_x",0))+float(piece.side)*.18,-.72,.72))
	var d: Dictionary=debris.back()
	d.theme=2;d.variant="semi_roof";d.fall_origin=pose.origin;d.fall_basis=pose.basis
	d.angle=0.0;d.spin=.75*float(piece.side);d.drift=0.0;d.flight_duration=2.35

func _update_debris(dt: float) -> void:
	if mode!=Mode.RUNNING:return
	for d in debris:
		if d.has("impact_age"):
			d.impact_age+=dt
			continue
		var previous: float=d.z
		var before: Transform3D=world.hazard_transform(d,elapsed-dt)
		d.z+=dt*(1.0/float(d.flight_duration) if d.has("flight_duration") else debris_rate())
		d.lane=clampf(d.lane+d.drift*dt,-.92,.92)
		d.angle+=d.spin*dt*(.72 if d.kind!=2 else 1.8)
		var after: Transform3D=world.hazard_transform(d,elapsed)
		if not d.checked:
			var bounds: AABB=world.hazard_bounds(d.kind,int(d.get("theme",0)),str(d.get("variant","")))
			var contact: Dictionary=contacts.sweep(before,after,bounds)
			if not contact.is_empty():
				d.checked=true
				if d.kind==4:
					health=minf(100,health+18);boost=minf(boost_max,boost+30);score+=300
					d.consumed=true;d.z=2.0
					notify("SUPPLY PICKUP  /  +18 HULL  +30 BOOST",2.0);play_sound("pickup")
				else:
					_apply_debris_contact(d,contact)
				if health<=0.0:break
		if d.kind<4 and not d.whooshed and d.z>=.81:
			d.whooshed=true
			if not d.checked and absf(d.lane-player_x)<.64:play_sound("pass_left" if d.lane<player_x else "pass_right")
		# Award a dodge only after the complete object is behind the rear bumper.
		if not d.checked and previous<1.075 and d.z>=1.075:
			d.checked=true
			var separation: float=absf(float(d.lane)-player_x)
			if d.kind<4 and route.air_height>3.0 and separation<.35:
				score+=125
			elif d.kind<4 and separation<.53:
				near_misses+=1;combo=mini(combo+1,5)
				var close: float=clampf(1.0-separation/.53,0.0,1.0)
				near_pulse=maxf(near_pulse,.30+.70*close);near_side=signf(d.lane-player_x)
				cam_roll_velocity+=near_side*close*.42
				score+=100*combo;boost=minf(boost_max,boost+7)
				notify("NEAR MISS  /  x%d  +%d"%[combo,100*combo],1.2);play_sound("near")
				if d.get("variant","")=="semi_roof":dodges.request(4)
				elif int(d.get("theme",0))==0:dodges.request_road(int(d.kind))
	contacts.reset()
	debris=debris.filter(func(d):return float(d.get("impact_age",0))<.75 and d.z<1.36)

func _apply_debris_contact(d: Dictionary, contact: Dictionary) -> void:
	var weight: float=[1.0,1.15,.72,.9][clampi(int(d.kind),0,3)]
	if int(d.get("theme",0))==2:weight*=1.18
	if d.get("variant","")=="semi_roof":weight=1.40
	var severity: float=weight*lerpf(.72,1.18,clampf((speed-60)/180.0,0,1))
	# Each distinct solid object damages once. Recovery time never makes it ghost.
	health=maxf(0,health-21.0*severity*setup_factor("damage"));hits+=1;combo=0;invulnerable=.3
	# Proportional plus flat, so a hit at 240 costs more than a hit at 120
	# instead of less. Routing it through the powertrain gives the existing
	# weight-transfer model a real deceleration to dive on.
	speed=maxf(40.0,speed*(1.0-0.10*severity)-(10.0+9.0*severity))
	powertrain.acceleration=minf(powertrain.acceleration,-62.0*severity)
	powertrain.throttle=minf(powertrain.throttle,0.15)
	powertrain.load=minf(powertrain.load,0.20)
	flash=maxf(flash,0.34+0.42*clampf(severity,0.6,1.7))
	var normal: Vector3=contact.normal
	var local_point: Vector3=contacts.truck_transform().affine_inverse()*contact.point
	var side: float=signf(local_point.x)
	if side==0:side=signf(float(d.lane)-player_x)
	glide_velocity=clampf(glide_velocity-side*.30*severity-normal.x*.48,-1.8,1.8)
	rear_slip_velocity=clampf(rear_slip_velocity-side*.50*severity,-2.8,2.8)
	d.impact_age=0.0;d.impact_transform=contact.transform
	# Contact, a short hold, then a visible deflection away from the chassis.
	var scatter: float=side if side!=0 else (-1.0 if hits%2 else 1.0)
	d.impact_velocity=normal*(10.0+weight*3.0)+Vector3(scatter*4.5,4.0,0.0)
	play_sound("wood_hit" if d.get("theme",0)==1 else ("metal_hit" if d.get("theme",0)==2 or d.kind==3 else "hit"))
	crashes.impact(int(d.kind),float(d.lane),int(d.get("theme",0)),contact.point,severity)
	cam_impulse_velocity-=normal*(1.7+2.1*severity)
	cam_impulse_velocity.y-=0.6+0.8*severity
	cam_roll_velocity-=side*(0.55+0.95*severity)
	yaw_kick_velocity-=side*(0.9+1.3*severity)
	world.truck.contact_kick(normal,severity)
	world.contact_burst(contact.point,normal,int(d.get("theme",0)),int(d.kind))
	dodges.cancel_pending()
	notify("CRITICAL HULL  /  FIND CLEAR ROAD" if health<=25 else "SOLID HIT  /  RECOVER YOUR LINE",1.6)

func _update_effects(dt: float) -> void :
	for e in effects:
		e.life -= dt
		if e.type == "probe": e.z -= dt * 0.7
	effects = effects.filter( func(e): return e.life > 0.0)

func _demo_target() -> float:
	var candidates: = [-0.82, -0.4, 0.0, 0.4, 0.82]
	var safest: = 0.0
	var best_cost: = INF
	for candidate in candidates:
		var cost: = absf(candidate - player_x) * 0.4 + absf(candidate) * 0.1
		for d in debris:
			if d.kind < 4 and not d.checked and d.z > 0.10 and d.z < 1.075:
				var rate: float=1.0/float(d.flight_duration) if d.has("flight_duration") else debris_rate()
				var eta: float = maxf(0.0, .95 - d.z) / rate
				var predicted_lane: float = clampf(d.lane + d.drift * eta, -0.92, 0.92)
				var shape: AABB=world.hazard_bounds(d.kind,int(d.get("theme",0)),str(d.get("variant","")))
				var yaw: float=world.scene_truck_yaw()
				var chassis: float=1.45*absf(cos(yaw))+2.94*absf(sin(yaw))
				var scale: float=route.lane_scale(0) if route.active else 5.8
				var clearance: float=(shape.size.length()*.5+chassis+.28)/scale
				cost += maxf(0.0, clearance - absf(candidate - predicted_lane)) * float(d.z) * 60.0
		if cost < best_cost: best_cost = cost;safest = candidate
	return safest

func notify(text: String, seconds: float = 2.0) -> void :
	message = text
	message_time = seconds

func finish(won: bool, reason: String, after_crash: bool = false) -> void :
	if mode == Mode.RESULTS: return
	if mode == Mode.CRASH and not after_crash: return
	if not won and health <= 0.0 and mode == Mode.RUNNING and not after_crash:
		crashes.begin(reason)
		return
	dodges.cancel_pending()
	mode = Mode.RESULTS
	result_title = "CHASE COMPLETE" if won else ("SURVEY INCOMPLETE" if health > 0.0 else "GAME OVER")
	result_reason = reason
	if won: score += health * 20.0
	best = maxi(best, int(score))
	_record_score(won)
	if won: checkpoint.clear()
	save_settings()
	_clear_touch()
	hud.rebuild()

func valid_checkpoint(data: Dictionary) -> bool:
	if data.get("version", 0) not in [1,2]: return false
	if data.get("stage", 0) not in ([1,2] if data.version == 1 else [1,2,3,4,5,6,7]): return false
	for key in ["score", "health", "boost", "boost_max", "charge", "probes", "hits", "near_misses", "tires", "distance"]:
		if not data.has(key) or not (data[key] is float or data[key] is int): return false
		if not is_finite(float(data[key])): return false
	return data.health > 0 and data.health <= 100 and data.boost_max >= 100 and data.boost_max <= 310 and data.tires > 0 and data.tires <= 1 and data.score >= 0 and data.probes >= 0

func can_retry_checkpoint() -> bool:
	return valid_checkpoint(checkpoint)

func save_checkpoint() -> void :
	checkpoint = {"version": 2, "stage": stage, "score": score, "health": health, "boost": boost, "boost_max": boost_max, "charge": charge, "probes": probes, "hits": hits, "near_misses": near_misses, "tires": tires, "distance": clampf(distance, 500.0, 1100.0), "run_id": run_id, "retry": checkpoint_retry, "assisted": run_assisted, "films": dodges.played_this_run, "last_film": dodges.last_play_time, "film_times": dodges.last_kind_times.duplicate(), "setup": str(loadout.get("setup", "stock"))}
	save_settings()

func retry_checkpoint() -> void :
	if not can_retry_checkpoint(): return
	var saved: = checkpoint.duplicate(true)
	start_chase(false)
	stage = int(saved.stage);stage_seen = stage;elapsed = stage * STAGE_LENGTH
	for key in ["score", "health", "boost", "boost_max", "charge", "probes", "hits", "near_misses", "tires", "distance"]: set(key, saved[key])
	run_id = str(saved.get("run_id", run_id))
	checkpoint_retry = true
	run_assisted = bool(saved.get("assisted", false)) or steering_assist or relaxed_hazards
	world.truck.apply_damage()
	speed = CRUISE_SPEEDS[stage]
	powertrain.reset(speed)
	route.enter(stage)
	world.reset_motion()
	dodges.played_this_run = int(saved.get("films", 0))
	dodges.last_play_time = float(saved.get("last_film", -1000.0))
	dodges.last_kind_times = saved.get("film_times", {}).duplicate()
	invulnerable = 2.0;spawn_timer = 1.25;sky_timer = 3.0;lens_timer = 7.0
	notify("CHECKPOINT %02d RESTORED  /  %s" % [stage, STAGE_NAMES[stage]], 3.2)
	hud.rebuild()

func _record_score(won: bool) -> void :

	for row in high_scores:
		if row.get("id", "") == run_id:
			if int(row.score) >= int(score): return
			high_scores.erase(row)
			break
	high_scores.append({"id": run_id, "score": int(score), "probes": probes, "won": won, "retry": checkpoint_retry, "assisted": run_assisted, "setup": str(loadout.get("setup", "stock"))})
	high_scores.sort_custom( func(a, b): return a.score > b.score)
	high_scores = high_scores.slice(0, 5)


func is_breathing() -> bool:
	if stage == 7 and route.orbit_progress() > 0.92: return true
	var front_time := fposmod(elapsed, STAGE_LENGTH)
	return (front_time >= 11.0 and front_time < 14.5) or (stage < 2 and front_time >= 25.0)

func toggle_option(key: String) -> void:
	if key not in ["steering_assist", "relaxed_hazards", "light_graphics", "mateo_voice"]: return
	set(key, not bool(get(key)))
	if key in ["steering_assist", "relaxed_hazards"] and mode == Mode.PAUSED:
		run_assisted = run_assisted or steering_assist or relaxed_hazards
	if key == "mateo_voice" and not mateo_voice and is_instance_valid(mateo_audio): mateo_audio.stop()
	save_settings()
	hud.rebuild()

func unlock_footage(front: int) -> void:
	if (front not in CHECKPOINT_FOOTAGE and front != FINALE_FOOTAGE) or front in footage_unlocked: return
	footage_unlocked.append(front)
	save_settings()

func setup_factor(key: String) -> float:
	return Loadout.factor(loadout, key)

func set_loadout(next: Dictionary) -> void:
	loadout = Loadout.sanitize(next)
	powertrain.accel_factor = setup_factor("accel")
	if is_instance_valid(world) and is_instance_valid(world.truck): world.truck.apply_loadout(loadout)
	save_settings()

func open_garage() -> void:
	if mode != Mode.MENU or is_instance_valid(film_overlay): return
	hud.settings_open = false
	mode = Mode.GARAGE
	# Park a clean, repaired truck on a straight highway for the preview.
	route.enter(0)
	stage = 0; stage_seen = 0; bend = 0.0; storm_offset = 0.0; distance = 900.0
	player_x = 0.0; velocity_x = 0.0; steer = 0.0; rear_slip = 0.0; rear_slip_velocity = 0.0
	speed = 0.0; boosting = false; braking = false; turbo_fx = 0.0; health = 100.0
	debris.clear(); effects.clear(); sky_debris.clear(); lens_projectiles.clear(); lens_marks.clear(); skid_trails.clear()
	_reset_water()
	shake = 0.0; flash = 0.0; lightning = 0.0; lens_kick = 0.0; flyby_pressure = 0.0; near_pulse = 0.0; cinematic_return = 0.0
	crashes.reset()
	world.reset_motion()
	world.truck.apply_loadout(loadout)
	garage.open()
	hud.rebuild()

func leave_garage(start: bool) -> void:
	if mode != Mode.GARAGE: return
	garage.close()
	mode = Mode.MENU
	save_settings()
	hud.rebuild()
	if start:
		if can_retry_checkpoint(): retry_checkpoint()
		else: start_chase()

func say_mateo(key: String, caption: String) -> bool:
	if mode != Mode.RUNNING or mateo_cooldown > 0.0: return false
	mateo_caption = caption
	mateo_caption_time = 2.8
	mateo_cooldown = 13.0
	var path := "res://assets/audio/" + key + ".wav"
	if mateo_voice and is_instance_valid(mateo_audio) and Media.available(path):
		mateo_audio.stream=load(path)
		mateo_audio.play()
	return true
