extends Control

const FILMS: = [
	{"file": "crate", "name": "CRATE", "title": "THREAD THE NEEDLE", "caption": "Timber cleared. Keep chasing."}, 
	{"file": "barrel", "name": "BARREL", "title": "SPLIT-SECOND SAVE", "caption": "Steel drum cleared. Clean escape."}, 
	{"file": "tire", "name": "TIRE", "title": "TOO CLOSE", "caption": "Rubber cleared. Nerves of steel."}, 
	{"file": "metal", "name": "ROOFING SHEET", "title": "RAZOR CLOSE", "caption": "Roofing cleared. Hold your line."}, 
	{"file": "semi", "name": "18-WHEELER", "title": "UNDER THE GIANT", "caption": "Overhead pass cleared. Eyes on the sky."}, 
	{"file": "cow", "name": "FLYING COW", "title": "HOLY COW", "caption": "Airborne cow cleared. Back to the chase."},
	{"file": "barn", "name": "CHECKPOINT 01", "title": "BARN BREAKOUT", "caption": "Silo County. Timber, barn doors and torn roofing.", "checkpoint": 1},
	{"file": "warehouse", "name": "CHECKPOINT 02", "title": "WAREHOUSE COLLAPSE", "caption": "Freight District. Concrete, steel and metal cladding.", "checkpoint": 2},
	{"file": "crosswind_curves", "name": "CHECKPOINT 03", "title": "CROSSWIND CURVES", "caption": "Wet curves. Crosswind. Brake before the bend.", "checkpoint": 3, "aspect": 898.0 / 512.0},
	{"file": "dirt_shortcut", "name": "CHECKPOINT 04", "title": "DIRT SHORTCUT", "caption": "Sharp right. Muddy shortcut. Find your grip.", "checkpoint": 4, "aspect": 898.0 / 512.0},
	{"file": "ridgeline_drift", "name": "CHECKPOINT 05", "title": "RIDGELINE JUMPS", "caption": "Big air. Muddy landing. Catch the slide.", "checkpoint": 5, "aspect": 898.0 / 512.0},
	{"file": "wild_hills", "name": "CHECKPOINT 06", "title": "WILD HILLS", "caption": "Curves and big crests. Hold the slide. Catch the landing.", "checkpoint": 6, "aspect": 898.0 / 512.0},
	{"file": "vortex_run", "name": "CHECKPOINT 07", "title": "VORTEX RUN", "caption": "The final approach. Circle the tornado. Hold on, Mateo.", "checkpoint": 7, "aspect": 898.0 / 512.0},
	{"file": "ridgeline_jumps", "name": "RIDGELINE / ORIGINAL", "title": "RIDGELINE JUMPS / ORIGINAL", "caption": "The first ridge crossing. An alternate checkpoint 05 film.", "checkpoint": 5, "aspect": 898.0 / 512.0},
	{"file": "final_transmission", "folder": "finale/", "name": "THE FINALE", "title": "FINAL TRANSMISSION", "caption": "Mateo's last recording from inside the vortex.", "checkpoint": 8, "aspect": 910.0 / 512.0, "duration": 18.0}
]
const PAGE_SIZE := 8
const SPACING: = 20.0
const REPEAT_SPACING: = 45.0
const MAX_PER_RUN: = 3
const AMBER: = Color("f4bc63")
const WHITE: = Color("ecf0e9")
const MINT: = Color("84dfb9")
const DISPLAY: = preload("res://assets/fonts/display.ttf")
const BODY: = preload("res://assets/fonts/interface.ttf")
const MONO: = preload("res://assets/fonts/telemetry.ttf")
const Media := preload("res://scripts/media.gd")
var game: Node2D
var streams: Dictionary = {}
var pending_kind: = -1
var pending_time: = 0.0
var pending_hits: = 0
var last_play_time: = -1000.0
var last_kind_times: Dictionary = {}
var played_this_run: = 0
var current_kind: = -1
var playing: = false
var gallery_session: = false
var return_mode: = 0
var player: VideoStreamPlayer
var film_age: = 0.0
var progress: ColorRect
var paused_audio: Dictionary = {}
var playback_failed: = false
var gallery_page := 0

func _ready() -> void :
	size = Vector2(1280, 720)
	z_index = 100
	hide()
	for i in range(FILMS.size()):
		var path: String = "res://assets/cinematics/" + film_folder(i) + FILMS[i].file + ".ogv"
		var film := Media.video(path)
		if film != null: streams[i] = film

func film_folder(kind: int) -> String:
	return FILMS[kind].get("folder", "checkpoints/" if FILMS[kind].has("checkpoint") else "dodges/")

func film_duration(kind: int) -> float:
	return float(FILMS[kind].get("duration", 6.0 if kind >= 6 else 5.0))

func reset_for_run() -> void :
	cancel_pending()
	_clear_player()
	_clear_ui()
	hide()
	gallery_session = false
	last_play_time = -1000.0
	last_kind_times.clear()
	played_this_run = 0

func cancel_pending() -> void :
	pending_kind = -1

func request_road(kind: int) -> void :
	if kind >= 0 and kind < 4: request(kind)

func request(kind: int) -> void :
	if not game.auto_dodges or game.mode != game.Mode.RUNNING: return
	if kind < 0 or kind >= 6 or not streams.has(kind): return
	if game.invulnerable > 0.0 or played_this_run >= MAX_PER_RUN: return
	if game.elapsed - last_play_time < SPACING: return
	if game.elapsed - float(last_kind_times.get(kind, -1000.0)) < REPEAT_SPACING: return

	if pending_kind >= 0 and not (kind < 4 and pending_kind >= 4): return
	pending_kind = kind
	pending_time = game.elapsed
	pending_hits = game.hits

func dispatch_pending() -> void :
	if pending_kind < 0: return
	if game.mode != game.Mode.RUNNING or game.health <= 0.0 or game.hits != pending_hits or not game.auto_dodges:
		cancel_pending()
		return

	if game.elapsed - pending_time < 0.22: return
	var kind: = pending_kind
	cancel_pending()
	if start_clip(kind, false):
		last_play_time = game.elapsed
		last_kind_times[kind] = game.elapsed
		played_this_run += 1

func toggle_auto() -> void :
	game.auto_dodges = not game.auto_dodges
	if not game.auto_dodges: cancel_pending()
	game.save_settings()
	game.hud.rebuild()

func _clear_ui() -> void :
	for child in get_children():
		if child is Control: child.hide()
		child.queue_free()
	progress = null

func _clear_player() -> void :
	playing = false
	if is_instance_valid(player):
		if player.finished.is_connected(finish_clip): player.finished.disconnect(finish_clip)
		player.stop()
		player.stream = null
	player = null
	for audio in paused_audio:
		if is_instance_valid(audio): audio.stream_paused = paused_audio[audio]
	paused_audio.clear()

func _silence_chase() -> void :
	for child in game.get_children():
		if child is AudioStreamPlayer:
			paused_audio[child] = child.stream_paused
			child.stream_paused = true

func start_clip(kind: int, from_gallery: bool = false) -> bool:
	if playing or not streams.has(kind): return false
	if kind>=6 and (not from_gallery or int(FILMS[kind].checkpoint) not in game.footage_unlocked): return false
	if not from_gallery and game.mode != game.Mode.RUNNING: return false
	if not from_gallery: return_mode = game.mode
	gallery_session = from_gallery
	current_kind = kind
	game.mode = game.Mode.CELEBRATION
	game._clear_touch()
	game.hud.rebuild()
	_clear_ui()
	show()
	film_age = 0.0
	playback_failed = false
	var black: = _rect(Rect2(0, 0, 1280, 720), Color.BLACK)
	black.mouse_filter = Control.MOUSE_FILTER_STOP
	player = VideoStreamPlayer.new()
	player.stream = streams[kind]
	player.expand = true
	player.size = Vector2(1280, 720)
	if FILMS[kind].has("aspect"):
		var aspect := float(FILMS[kind].aspect)
		player.size = Vector2(minf(1280.0, 720.0 * aspect), minf(720.0, 1280.0 / aspect))
		player.position = (Vector2(1280, 720) - player.size) * 0.5
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(player)
	player.finished.connect(finish_clip)
	_rect(Rect2(0, 0, 1280, 78), Color(0.015, 0.035, 0.043, 0.76))
	_rect(Rect2(0, 651, 1280, 69), Color(0.015, 0.035, 0.043, 0.86))
	_label("MATEO'S FOOTAGE" if from_gallery else "CINEMATIC DODGE", Vector2(34, 12), 12, MINT, MONO)
	_label(FILMS[kind].title, Vector2(33, 31), 29, WHITE, DISPLAY)
	_label(FILMS[kind].name, Vector2(982, 29), 17, AMBER, MONO)
	_label(FILMS[kind].caption, Vector2(34, 672), 15, WHITE, BODY)
	_button("BACK TO FILMS" if from_gallery else "KEEP CHASING   >", Rect2(1032, 664, 214, 37), finish_clip)
	_label("SPACE / ESC / A TO SKIP", Vector2(802, 676), 10, AMBER, MONO)
	progress = _rect(Rect2(0, 716, 0, 4), AMBER)
	_silence_chase()
	playing = true
	player.play()
	if game.demo: print("DODGE_FILM: ", FILMS[kind].file, " at chase ", snappedf(game.elapsed, 0.01), "s")
	return true

func finish_clip() -> void :
	if not playing: return
	_clear_player()
	_clear_ui()
	game._clear_touch()
	if gallery_session:
		_draw_gallery()
	else:
		hide()
		game.mode = return_mode
		game.hud.rebuild()

func focus_lost() -> void :
	if playing and not gallery_session:
		return_mode = game.Mode.PAUSED
		finish_clip()
	elif playing:
		finish_clip()

func handle_input(event: InputEvent) -> void :
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER]:
			if playing: finish_clip()
			elif event.physical_keycode == KEY_ESCAPE: close_gallery()
	elif event is InputEventJoypadButton and event.pressed:
		if playing and event.button_index in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_START]: finish_clip()
		elif not playing and event.button_index in [JOY_BUTTON_B, JOY_BUTTON_START]: close_gallery()
	get_viewport().set_input_as_handled()

func show_gallery() -> void :
	if game.mode not in [game.Mode.MENU, game.Mode.PAUSED, game.Mode.RESULTS]: return
	return_mode = game.mode
	game.mode = game.Mode.CELEBRATION
	gallery_session = true
	game._clear_touch()
	game.hud.rebuild()
	_draw_gallery()

func _draw_gallery() -> void :
	_clear_ui()
	show()
	_rect(Rect2(0, 0, 1280, 720), Color("07151b"))
	_label("STORM CHASER / CINEMATICS", Vector2(56, 29), 12, AMBER, MONO)
	_label("MATEO'S FOOTAGE", Vector2(53, 54), 38, WHITE, DISPLAY)
	_label("Six close calls. Eight checkpoint films. One final transmission. Earn them on the chase.", Vector2(56, 109), 16, Color("a1b8b7"), BODY)
	var page_count := ceili(float(FILMS.size()) / PAGE_SIZE)
	gallery_page = clampi(gallery_page, 0, page_count - 1)
	var start := gallery_page * PAGE_SIZE
	for i in range(start, mini(start + PAGE_SIZE, FILMS.size())):
		var slot := i - start
		var x: = 56.0 + (slot % 4) * 298.0
		var y: = 158.0 + floori(slot / 4.0) * 216.0
		var r: = Rect2(x, y, 278, 193)
		var folder: String = film_folder(i)
		var photo: String = "res://assets/cinematics/" + folder + FILMS[i].file + ".jpg"
		var unlocked: bool = not FILMS[i].has("checkpoint") or int(FILMS[i].get("checkpoint", 0)) in game.footage_unlocked
		if Media.available(photo):
			var poster: = TextureRect.new()
			poster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			poster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			poster.texture = load(photo)
			poster.position = r.position
			poster.size = r.size
			poster.clip_contents = true
			poster.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(poster)
		_rect(Rect2(x, y + 144, 278, 49), Color(0.015, 0.035, 0.043, 0.9))
		_label(FILMS[i].name, Vector2(x + 12, y + 154), 14, WHITE, DISPLAY)
		var b: = _button("", r, start_clip.bind(i, true), true)
		b.tooltip_text = "Watch " + FILMS[i].title.to_lower()
		b.disabled = not streams.has(i) or not unlocked
		if unlocked and not streams.has(i):
			_rect(r, Color(0.01,0.025,0.03,0.55))
			_label("FILM NOT INSTALLED", Vector2(x+13,y+85),13,Color("94aaa9"),MONO)
		if not unlocked:
			_rect(r, Color(0.01,0.025,0.03,0.67))
			_label("COMPLETE THE TORNADO LAP" if int(FILMS[i].checkpoint) == game.FINALE_FOOTAGE else "REACH CHECKPOINT %02d" % int(FILMS[i].checkpoint), Vector2(x+13,y+85),13,AMBER,MONO)
		elif i>=6: _label("UNLOCKED",Vector2(x+12,y+176),9,MINT,MONO)
		if slot == 0 and not b.disabled: b.grab_focus()
	_label("SPACE / ESC / A skips a film. Your chase stays paused during playback.", Vector2(56, 625), 13, Color("a1b8b7"), BODY)
	var Loadout = game.Loadout
	_label("INTERCEPTOR  /  " + Loadout.summary(game.loadout) + "  /  " + Loadout.setup_name(game.loadout) + " SETUP", Vector2(56, 588), 11, MINT if not Loadout.is_stock_look(game.loadout) else Color("7f9695"), MONO)
	if page_count > 1:
		var previous := _button("< PREVIOUS", Rect2(56, 651, 145, 36), _change_page.bind(-1))
		previous.focus_mode = Control.FOCUS_ALL
		previous.disabled = gallery_page == 0
		_label("%02d / %02d" % [gallery_page + 1, page_count], Vector2(221, 660), 12, MINT, MONO)
		var next := _button("NEXT >", Rect2(316, 651, 145, 36), _change_page.bind(1))
		next.focus_mode = Control.FOCUS_ALL
		next.disabled = gallery_page == page_count - 1
		if not next.disabled: next.grab_focus()
		elif not previous.disabled: previous.grab_focus()
	var close_button := _button("RETURN TO CHASE" if return_mode == game.Mode.PAUSED else ("BACK TO RESULTS" if return_mode == game.Mode.RESULTS else "RETURN TO BASE"), Rect2(962, 641, 262, 45), close_gallery)
	# Focus is only seeded on tile 0 and on the page buttons, and all of those
	# can be disabled at once. That cannot happen with today's 15 films and a
	# page size of 8, because there are always two pages and a page button
	# always takes focus -- but it would strand a controller on this screen the
	# moment the film list fits on one page. Guard it rather than depend on the
	# catalog size.
	if get_viewport().gui_get_focus_owner() == null: close_button.grab_focus()

func _change_page(direction: int) -> void:
	gallery_page += direction
	_draw_gallery()

func close_gallery() -> void :
	_clear_player()
	_clear_ui()
	hide()
	gallery_session = false
	game.mode = return_mode
	game.hud.rebuild()

func _process(delta: float) -> void :
	if not playing: return
	film_age += delta
	if is_instance_valid(progress) and is_instance_valid(player): progress.size.x = 1280.0 * clampf(player.stream_position / film_duration(current_kind), 0.0, 1.0)

	if film_age > film_duration(current_kind) + 4.0:
		playback_failed = true
		finish_clip()

func _rect(r: Rect2, color: Color) -> ColorRect:
	var c: = ColorRect.new()
	c.position = r.position
	c.size = r.size
	c.color = color
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	return c

func _label(value: String, at: Vector2, font_size: int, color: Color, font: Font) -> Label:
	var label: = Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _button(value: String, r: Rect2, action: Callable, clear: bool = false) -> Button:
	var b: = Button.new()
	b.text = value
	b.position = r.position
	b.size = r.size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", DISPLAY)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", WHITE)
	b.add_theme_stylebox_override("normal", game.hud.style(Color.TRANSPARENT if clear else Color("19363d"), Color("34545a"), 5))
	b.add_theme_stylebox_override("hover", game.hud.style(Color(0.9, 0.7, 0.4, 0.08) if clear else Color("29474d"), AMBER, 5))
	b.add_theme_stylebox_override("focus", game.hud.style(Color.TRANSPARENT, AMBER, 5))
	b.pressed.connect(action)

	b.focus_mode = Control.FOCUS_ALL
	add_child(b)
	return b

func _exit_tree() -> void :
	_clear_player()
