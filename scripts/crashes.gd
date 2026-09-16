extends Node2D

const FILM: = "res://assets/cinematics/final-impact.ogv"
const POSTER: = "res://assets/cinematics/final-impact.jpg"
const Media := preload("res://scripts/media.gd")
var game: Node2D
var movie_path: = FILM
var particles: Array[Dictionary] = []
var impact_age: = 10.0
var impact_strength: = 0.0
var hit_stop: = 0.0
var hit_stop_span: = 0.0
var crunch_delay: = -1.0
var scatter_delay: = -1.0
var scatter_kind: = 0
var origin: = Vector2.ZERO
var contact_origin:=Vector3.ZERO
var projection_pending:=false
var active: = false
var wreck_result: = false
var final_age: = 0.0
var film_age: = 0.0
var reason: = ""
var overlay: Control
var player: VideoStreamPlayer
var poster: Texture2D
var audio_states: Dictionary = {}
var rumble: AudioStreamPlayer
var crunch: AudioStreamPlayer
var rng: = RandomNumberGenerator.new()

func _ready() -> void :
	z_index = 15
	rng.seed = 58133
	if Media.available(POSTER): poster = load(POSTER)
	rumble = AudioStreamPlayer.new()
	rumble.stream = Media.audio("res://assets/audio/heavy_pass.wav")
	rumble.pitch_scale = 0.66
	rumble.volume_db = -6.0
	add_child(rumble)
	crunch = AudioStreamPlayer.new()
	crunch.stream = Media.audio("res://assets/audio/lens_hit.wav")
	crunch.volume_db = -8.0
	add_child(crunch)

func reset() -> void :
	active = false
	wreck_result = false
	_clear_film()
	particles.clear()
	impact_age = 10.0
	impact_strength = 0.0
	hit_stop = 0.0
	hit_stop_span = 0.0
	crunch_delay = -1.0
	scatter_delay = -1.0
	projection_pending=false
	rumble.stop()
	crunch.stop()
	queue_redraw()

func impact(kind: int, lane: float, building_theme: int = 0, contact_point: Vector3 = Vector3(INF,INF,INF), severity: float = 1.0) -> void :
	game.haptic(int(lerpf(95.0, 180.0, clampf((severity - .6) / 1.1, 0.0, 1.0))), lerpf(.55, 1.0, clampf((severity - .6) / 1.1, 0.0, 1.0)))
	impact_age = 0.0
	impact_strength = clampf(severity,.55,1.75)
	# The hold scales with the blow: a sign clip is not a semi roof at 240.
	hit_stop = 0.0 if game.calm_fx else (.055 + .085 * clampf(severity,.6,1.7))
	hit_stop_span = maxf(hit_stop,.0001)
	var side: float = signf(lane - game.player_x)
	if side == 0.0: side = 1.0
	if not contact_point.is_finite():contact_point=game.world.truck.position+Vector3(side*.75,.9,1.6)
	contact_origin=contact_point;projection_pending=true
	origin = game.world.camera.unproject_position(contact_point)
	game.shake = maxf(game.shake, 16.0 * impact_strength)
	particles.clear()
	var palette: = [Color("9b6d3e"), Color("9aaeb1"), Color("303b40"), Color("d0dad8")]
	if building_theme == 1: palette = [Color("835849"), Color("956451"), Color("735948"), Color("a5adb0")]
	elif building_theme == 2: palette = [Color("8c9999"), Color("687c86"), Color("5d747d"), Color("849ba0")]
	elif building_theme == 3: palette = [Color("655c47"),Color("7a684b"),Color("514735"),Color("8b805f")]
	var strength: float = clampf((impact_strength - .55) / 1.2, 0.0, 1.0)
	# Spray away from the contact rather than in a fixed upward fan.
	var away: Vector2 = (origin - game.world.camera.unproject_position(game.world.truck.position + Vector3(0,1.0,0))).normalized()
	var base: float = away.angle() if away.length_squared() > .1 else -1.5
	for i in range(int(lerpf(14.0, 34.0, strength)) if not game.calm_fx else 6):
		var angle: float = base + rng.randf_range( - 1.05, 1.05)
		var velocity: = Vector2(cos(angle), sin(angle)) * rng.randf_range(120.0, 680.0) * (.7 + .5 * impact_strength)
		particles.append({"p": origin, "v": velocity, "life": rng.randf_range(0.35, 1.25), "size": rng.randf_range(3.0, 12.0), "spin": rng.randf_range(-9.0, 9.0), "angle": rng.randf() * TAU, "spark": i % 3 == 0, "color": palette[clampi(kind, 0, 3)]})
	# Sub thump now, mid crunch at +25 ms, scatter at +85 ms. Fired together
	# they mush into one hit; staggered they read as mass arriving.
	game.landing_audio.pitch_scale = lerpf(.86, .52, strength)
	game.landing_audio.volume_db = lerpf(-14.0, -3.0, strength)
	game.landing_audio.play()
	rumble.pitch_scale = lerpf(.78, .50, strength)
	rumble.volume_db = lerpf(-12.0, -2.5, strength)
	rumble.play()
	crunch.pitch_scale = [0.73, 0.88, 0.6, 1.12][clampi(kind, 0, 3)] * lerpf(1.10, .86, strength)
	crunch.volume_db = lerpf(-13.0, -3.0, strength)
	crunch_delay = .025
	scatter_delay = .085
	scatter_kind = kind

func sync_projection() -> void:
	if not projection_pending:return
	var next: Vector2=game.world.camera.unproject_position(contact_origin)
	for p in particles:p.p+=next-origin
	origin=next;projection_pending=false

func begin(why: String) -> void :
	if active or wreck_result: return
	reason = why
	active = true
	final_age = 0.0
	film_age = 0.0
	game.health = 0.0
	game.dodges.cancel_pending()
	game.mode = game.Mode.CRASH
	game._clear_touch()
	game.hud.rebuild()
	if impact_age > 0.3: impact(3, game.player_x, 0, Vector3(INF,INF,INF), 1.7)
	game.world.mateo.pose = game.world.mateo.Pose.DUCK
	game.world.mateo.previous_pose = game.world.mateo.pose
	game.world.mateo.blend = 1.0
	game.world.mateo._apply_pose()
	if game.demo: print("FINAL_IMPACT: at chase ", game.elapsed, "s")

func _process(delta: float) -> void :
	var dt: = minf(delta, 0.05)
	if game.mode in [game.Mode.RUNNING, game.Mode.CRASH]:
		impact_age += dt
		hit_stop = maxf(0.0, hit_stop - dt)
		if crunch_delay > 0.0:
			crunch_delay -= dt
			if crunch_delay <= 0.0: crunch.play()
		if scatter_delay > 0.0:
			scatter_delay -= dt
			if scatter_delay <= 0.0: game.play_sound("wood_hit" if scatter_kind == 1 else "metal_hit")
		for p in particles:
			p.life -= dt
			p.p += p.v * dt
			p.v.y += 650.0 * dt
			p.angle += p.spin * dt
		particles = particles.filter( func(p): return p.life > 0.0)
	if active:
		final_age += dt
		if not is_instance_valid(overlay) and final_age >= 0.72: _play_final()
		elif is_instance_valid(overlay):
			film_age += delta
			if film_age >= 13.0: complete()
	queue_redraw()

func _play_final() -> void :
	var film := Media.video(movie_path)
	if film == null:
		complete()
		return
	overlay = Control.new()
	overlay.z_index = 100
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var black: = ColorRect.new()
	black.color = Color.BLACK
	black.size = overlay.size
	overlay.add_child(black)
	player = VideoStreamPlayer.new()
	player.stream = film
	player.expand = true
	player.size = overlay.size
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(player)
	for y in [0, 670]:
		var bar: = ColorRect.new()
		bar.position = Vector2(0, y)
		bar.size = Vector2(1280, 50)
		bar.color = Color(0.015, 0.025, 0.03, 0.86)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(bar)
	var title: = Label.new()
	title.text = "FINAL IMPACT  /  CHASE LOST"
	title.position = Vector2(28, 16)
	title.add_theme_font_override("font", game.hud.MONO)
	title.add_theme_color_override("font_color", Color("e8ad78"))
	overlay.add_child(title)
	var skip: = Button.new()
	skip.text = "SKIP TO GAME OVER   [SPACE / ESC / A]"
	skip.position = Vector2(856, 679)
	skip.size = Vector2(400, 32)
	skip.focus_mode = Control.FOCUS_NONE
	skip.pressed.connect(complete)
	overlay.add_child(skip)
	for child in game.get_children():
		if child is AudioStreamPlayer:
			audio_states[child] = child.stream_paused
			child.stream_paused = true
	rumble.stop()
	crunch.stop()
	player.finished.connect(complete)
	player.play()
	if game.demo: print("FINAL_FILM_STARTED")

func _clear_film() -> void :
	if is_instance_valid(player):
		player.stop()
		player.stream = null
	player = null
	if is_instance_valid(overlay):
		overlay.hide()
		overlay.queue_free()
	overlay = null
	for audio in audio_states:
		if is_instance_valid(audio): audio.stream_paused = audio_states[audio]
	audio_states.clear()

func complete() -> void :
	if not active: return
	active = false
	wreck_result = true
	_clear_film()
	particles.clear()
	hit_stop = 0.0
	game.speed = 0.0
	game.boosting = false
	game.turbo_fx = 0.0
	game.shake = 0.0
	game.flash = 0.0
	game.finish(false, reason, true)
	if game.demo: print("FINAL_GAME_OVER")

func handle_input(event: InputEvent) -> void :
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_M: game.toggle_sound()
		elif event.physical_keycode in [KEY_SPACE, KEY_ESCAPE, KEY_ENTER] and final_age > 0.3: complete()
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_START] and final_age > 0.3: complete()
	get_viewport().set_input_as_handled()

func _draw() -> void :
	if game.mode == game.Mode.RESULTS and wreck_result and poster != null:
		draw_texture_rect(poster, Rect2(0, 0, 1280, 720), false)
		return
	if game.mode not in [game.Mode.RUNNING, game.Mode.PAUSED, game.Mode.CRASH]: return
	if not game.calm_fx and impact_age < 0.45:
		var alpha: = (1.0 - impact_age / 0.45) * 0.65
		for i in range(11):
			var direction: = Vector2.from_angle(i * TAU / 11.0)
			draw_line(origin + direction * (25.0 + impact_age * 300.0), origin + direction * (45.0 + impact_age * 500.0), Color(1.0, 0.78, 0.49, alpha * 0.45), 1.4, true)
	for p in particles:
		var alpha: float = clampf(p.life * 2.0, 0.0, 1.0)
		if p.spark and not game.calm_fx:
			draw_line(p.p, p.p - p.v.normalized() * p.size * 3.0, Color(1.0, 0.61, 0.15, alpha), 2.5, true)
		else:
			draw_set_transform(p.p, p.angle)
			var c: Color = p.color
			c.a = alpha
			draw_colored_polygon(PackedVector2Array([Vector2( - p.size, - p.size * 0.35), Vector2(p.size, - p.size * 0.6), Vector2(p.size * 0.4, p.size)]), c)
			draw_set_transform(Vector2.ZERO)
	if impact_age < 1.2:
		for i in range(7):
			var at: = origin + Vector2((i - 3) * 19.0, - impact_age * (50 + i * 9))
			draw_circle(at, 12.0 + impact_age * 25.0, Color(0.19, 0.22, 0.22, (1.0 - impact_age / 1.2) * 0.15))
	if game.health > 0 and game.health <= 30:
		var at: Vector2 = game.world.camera.unproject_position(game.world.truck.position + Vector3(0, 1.6, -1.0))
		for i in range(5):
			var phase: float = fposmod(game.elapsed * 0.7 + i * 0.2, 1.0)
			draw_circle(at + Vector2(sin(i + phase * 3.0) * 12, - phase * 70), 8 + phase * 19, Color(0.1, 0.13, 0.14, (1 - phase) * 0.24))

func _exit_tree() -> void :
	_clear_film()
