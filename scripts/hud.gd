extends Control
var game: Node2D
const AMBER: = Color("f4bc63")
const WHITE: = Color("ecf0e9")
const MINT: = Color("84dfb9")
const MUTED: = Color("94aaa9")
const INK: = Color(0.025, 0.055, 0.063, 0.91)
const EDGE: = Color(0.49, 0.66, 0.64, 0.25)
const COVER: = preload("res://assets/art/key-art.png")
const DISPLAY: = preload("res://assets/fonts/display.ttf")
const BODY: = preload("res://assets/fonts/interface.ttf")
const MONO: = preload("res://assets/fonts/telemetry.ttf")
## The debrief panel; its buttons, including MATEO'S FOOTAGE, must fit inside it.
const RESULTS_PANEL := Rect2(324, 175, 632, 494)
var buttons: Array[Button] = []
var probe_button: Button
var audio_button: Button
var settings_open := false
var settings_focus := 0
var touch_buttons: Dictionary = {}
## Each finger owns its hold independently, even when two share one button.
## Index -1 is the optional desktop mouse; real touch indices are nonnegative.
var touch_points: Dictionary = {}
var touch_taps: Dictionary = {}

func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(1280, 720)
	rebuild()

func panel(r: Rect2, color: Color = INK) -> void :
	draw_style_box(style(color, EDGE, 12), r)

func style(fill: Color, border: Color, radius: int = 8) -> StyleBoxFlat:
	var box: = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	return box

func text_at(text: String, x: float, y: float, font_size: int = 16, color: Color = WHITE, font: Font = BODY) -> void :
	draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

## DATA amounts in the wallet run to six figures, where 128450 is a number you
## have to read twice and 128,450 is one you can say out loud. The score itself
## keeps its zero-padded %06d telemetry look; this is for money.
static func data_amount(value: int) -> String:
	var digits: = str(absi(value))
	var grouped: = ""
	for i in range(digits.length()):
		if i > 0 and (digits.length() - i) % 3 == 0: grouped += ","
		grouped += digits[i]
	return ("-" if value < 0 else "") + grouped

func centered(text: String, x: float, y: float, font_size: int = 16, color: Color = WHITE, font: Font = BODY) -> void :
	var width: = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	text_at(text, x - width * 0.5, y, font_size, color, font)

func bar(r: Rect2, fraction: float, color: Color) -> void :
	draw_style_box(style(Color(0.32, 0.45, 0.45, 0.2), Color.TRANSPARENT, 3), r)
	if fraction > 0.0: draw_style_box(style(color, Color.TRANSPARENT, 3), Rect2(r.position, Vector2(r.size.x * clampf(fraction, 0.0, 1.0), r.size.y)))

func button(label: String, r: Rect2, callback: Callable, primary: bool = false) -> Button:
	var b: = Button.new()
	b.position = r.position
	b.size = r.size
	b.text = label
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", DISPLAY)
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color("15262b") if primary else WHITE)
	b.add_theme_color_override("font_hover_color", Color("15262b") if primary else WHITE)
	b.add_theme_color_override("font_focus_color", Color("15262b") if primary else WHITE)
	b.add_theme_color_override("font_pressed_color", Color("15262b") if primary else WHITE)
	b.add_theme_stylebox_override("normal", style(AMBER if primary else Color("122a30"), AMBER if primary else EDGE))
	b.add_theme_stylebox_override("hover", style(Color("ffd18a") if primary else Color("25424a"), AMBER))
	b.add_theme_stylebox_override("pressed", style(Color("dc9b45") if primary else Color("0c2025"), AMBER))
	b.add_theme_stylebox_override("focus", style(Color(0, 0, 0, 0), AMBER, 8))
	b.add_theme_stylebox_override("disabled", style(Color("162d31"), EDGE))
	b.add_theme_color_override("font_disabled_color", MUTED)
	if game.mode == game.Mode.RUNNING: b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(callback)
	add_child(b)
	buttons.append(b)
	return b

func rebuild() -> void :
	game._clear_touch()
	touch_buttons.clear()
	for b in buttons: b.hide(); b.queue_free()
	buttons.clear()
	probe_button = null
	audio_button = null
	if settings_open and game.mode in [game.Mode.MENU, game.Mode.PAUSED]:
		_build_settings()
		queue_redraw()
		return
	settings_open = false
	if game.mode == game.Mode.MENU:
		var start: = button("RESUME CHECKPOINT   >" if game.can_retry_checkpoint() else "START CHASING   >", Rect2(72, 470, 302, 80 if game.touch_controls else 60), game.retry_checkpoint if game.can_retry_checkpoint() else game.start_chase, true)
		start.grab_focus()
		if game.can_retry_checkpoint(): button("NEW CHASE", Rect2(75, 550, 190, 38), game.start_chase)
		button("DRIVING & DISPLAY", Rect2(390, 478, 188, 44), open_settings)
		var film := button("WATCH STORM FILM", Rect2(594, 478, 202, 44), game.show_film)
		film.disabled = not game.has_storm_film()
		button("MATEO'S FOOTAGE", Rect2(812, 478, 200, 44), game.dodges.show_gallery)
		button("MATEO'S GARAGE", Rect2(1030, 478, 208, 44), game.open_garage)

		audio_button = button("SOUND", Rect2(1107, 642, 108, 42), game.toggle_sound)
	elif game.mode == game.Mode.RUNNING:
		button("PAUSE" if game.touch_controls else "II", Rect2(1162, 88, 90, 80) if game.touch_controls else Rect2(1200, 23, 42, 34), game.pause_chase)
		audio_button = button("SND", Rect2(1060, 88, 90, 80) if game.touch_controls else Rect2(1148, 23, 42, 34), game.toggle_sound)
		probe_button = button("TRANSMIT PROBE", Rect2(1009, 608, 243, 80) if game.touch_controls else Rect2(1009, 631, 233, 39), game.deploy_probe, true)
		if game.touch_controls:
			_touch_button("left", "<", Rect2(24, 412, 112, 104))
			_touch_button("right", ">", Rect2(148, 412, 112, 104))
			_touch_button("brake", "BRAKE", Rect2(1016, 412, 112, 104))
			_touch_button("boost", "BOOST", Rect2(1140, 412, 112, 104), true)
	elif game.mode == game.Mode.PAUSED:
		var resume: = button("RESUME CHASE", Rect2(434, 341, 412, 53), game.resume_chase, true)
		resume.grab_focus()
		button("DRIVING & DISPLAY", Rect2(434, 408, 198, 45), open_settings)
		audio_button = button("SOUND", Rect2(646, 408, 200, 45), game.toggle_sound)
		button("RETURN TO BASE", Rect2(434, 472, 412, 46), game.return_to_menu)
		button("MATEO'S FOOTAGE", Rect2(434, 535, 412, 40), game.dodges.show_gallery)
	elif game.mode == game.Mode.UPGRADE:
		for i in range(3):
			var b: = button("SELECT UPGRADE", Rect2(285 + i * 244, 451, 222, 80 if game.touch_controls else 48), game.choose_upgrade.bind(i), i == 0)
			if i == 0: b.grab_focus()
	elif game.mode == game.Mode.RESULTS:
		if game.can_retry_checkpoint():
			var retry: = button("RETRY CHECKPOINT   [%s]" % ("A" if game.pad_connected() else "R"), Rect2(352, 489, 284, 54), game.retry_checkpoint, true)
			retry.grab_focus()
			button("NEW CHASE", Rect2(650, 489, 168, 54), game.start_chase)
			button("BASE", Rect2(832, 489, 96, 54), game.return_to_menu)
		else:
			var again: = button("CHASE AGAIN   [%s]" % ("A" if game.pad_connected() else "R"), Rect2(410, 489, 280, 54), game.start_chase, true)
			again.grab_focus()
			button("BASE", Rect2(706, 489, 164, 54), game.return_to_menu)
		button("MATEO'S FOOTAGE",Rect2(524, 614, 232, 36),game.dodges.show_gallery)
	queue_redraw()

func _touch_button(action: String, label: String, area: Rect2, primary: bool = false) -> void:
	var control := button(label, area, func(): pass, primary)
	# Driving reads real screen events, not the single emulated mouse pointer.
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.toggle_mode = true
	control.add_theme_font_size_override("font_size", 23)
	touch_buttons[action] = control

func clear_touch_points() -> void:
	touch_points.clear()
	touch_taps.clear()
	for control in touch_buttons.values():
		if is_instance_valid(control): control.set_pressed_no_signal(false)

func _touch_action_at(point: Vector2) -> String:
	for action in touch_buttons:
		if touch_buttons[action].get_global_rect().has_point(point): return action
	return ""

func _touch_tap_at(point: Vector2) -> Button:
	for control in buttons:
		if control.visible and not control.disabled and control not in touch_buttons.values() and control.get_global_rect().has_point(point): return control
	return null

func _sync_touch_points() -> void:
	var held: Array = touch_points.values()
	game.touch_left = "left" in held
	game.touch_right = "right" in held
	game.touch_brake = "brake" in held
	game.touch_boost = "boost" in held
	for action in touch_buttons:
		touch_buttons[action].set_pressed_no_signal(action in held)

func handle_touch_input(event: InputEvent) -> bool:
	if not game.touch_controls or game.mode != game.Mode.RUNNING or settings_open: return false
	var index := -1
	var point := Vector2.ZERO
	var released := false
	var dragged := false
	if event is InputEventScreenTouch:
		index = event.index; point = event.position
		released = not event.pressed or event.canceled
		if touch_taps.has(index):
			if released:
				var control: Button = touch_taps[index]
				touch_taps.erase(index)
				if not event.canceled and is_instance_valid(control) and not control.disabled and control.get_global_rect().has_point(point): control.pressed.emit()
			return true
		if not released and _touch_action_at(point).is_empty():
			var control := _touch_tap_at(point)
			if control != null:
				touch_taps[index] = control
				return true
	elif event is InputEventScreenDrag:
		index = event.index; point = event.position; dragged = true
		if touch_taps.has(index): return true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Godot can mirror finger zero as a mouse. It must not own a second hold.
		if event.device == -1: return not _touch_action_at(event.position).is_empty() or _touch_tap_at(event.position) != null
		point = event.position; released = not event.pressed
	elif event is InputEventMouseMotion:
		if event.device == -1: return not _touch_action_at(event.position).is_empty() or _touch_tap_at(event.position) != null
		point = event.position; dragged = true
		released = not (event.button_mask & MOUSE_BUTTON_MASK_LEFT)
	else:
		return false
	if released:
		if not touch_points.has(index): return false
		touch_points.erase(index)
	elif dragged:
		if not touch_points.has(index): return false
		touch_points[index] = _touch_action_at(point)
	else:
		var action := _touch_action_at(point)
		if action.is_empty(): return false
		touch_points[index] = action
	_sync_touch_points()
	return true

func _process(_dt: float) -> void :
	visible = game.mode not in [game.Mode.CELEBRATION, game.Mode.CRASH, game.Mode.CHECKPOINT, game.Mode.VORTEX, game.Mode.GARAGE] and not (game.cinema_view and game.mode == game.Mode.RUNNING and not game.touch_controls)
	if is_instance_valid(probe_button):
		var ready: bool = game.charge >= 99.99 and game.in_sampling_range()
		probe_button.disabled = not ready
		probe_button.text = ("SEND PROBE" if game.touch_controls else "SEND PROBE   [SPACE / X]") if ready else "PROBE CHARGING   %d%%" % int(game.charge)
	if is_instance_valid(audio_button):
		audio_button.text = ("OFF" if game.muted else "SND") if game.mode == game.Mode.RUNNING else ("SOUND OFF" if game.muted else "SOUND ON")

func _draw() -> void :
	if game.cinema_view and game.touch_controls and game.mode == game.Mode.RUNNING: return
	if settings_open:
		if game.mode == game.Mode.MENU: draw_texture_rect(COVER, Rect2(0,0,1280,720),false)
		_draw_settings()
		return
	if game.mode == game.Mode.MENU:
		_draw_menu()
		return
	if game.mode == game.Mode.GARAGE: return
	if not (game.mode == game.Mode.RESULTS and game.crashes.wreck_result): _draw_dashboard()
	if game.mode == game.Mode.PAUSED: _draw_pause()
	elif game.mode == game.Mode.UPGRADE: _draw_upgrade()
	elif game.mode == game.Mode.RESULTS: _draw_results()

func _draw_menu() -> void :
	draw_texture_rect(COVER, Rect2(0, 0, 1280, 720), false)
	for i in range(128):
		var alpha: = 0.9 * pow(1.0 - float(i) / 128.0, 2.2)
		draw_rect(Rect2(i * 10, 0, 10, 720), Color(0.015, 0.04, 0.051, alpha))
	for i in range(40): draw_rect(Rect2(0, 520 + i * 5, 1280, 5), Color(0.008, 0.025, 0.032, i / 40.0 * 0.86))
	draw_circle(Vector2(81, 65), 5.0, AMBER)
	text_at("FIELD OPERATIONS   /   SKYFALL 3D", 102, 70, 13, AMBER, MONO)
	text_at("STORM", 68, 228, 91, WHITE, DISPLAY)
	text_at("CHASER", 68, 324, 91, WHITE, DISPLAY)
	draw_rect(Rect2(75, 345, 56, 3), AMBER)
	text_at("Follow the vortex.", 75, 391, 26, WHITE, BODY)
	text_at("Dodge the debris. Bring the data home.", 75, 426, 19, Color("c6d3cd"), BODY)
	text_at("8 LEVELS.  7 FILMS.  14 SAVE FLAGS.  REACH THE VORTEX.", 75, 454, 11, AMBER, MONO)
	text_at("HOLD THE ARROWS TO STEER" if game.touch_controls else "A / D   STEER     W / SHIFT   BOOST", 75, 605, 13, WHITE, MONO)
	text_at("USE YOUR OTHER THUMB FOR BOOST OR BRAKE" if game.touch_controls else "S       BRAKE     SPACE       PROBE", 75, 630, 13, WHITE, MONO)
	text_at("Tap SEND PROBE when charged. Turn your phone sideways." if game.touch_controls else "Controller: stick steer  /  A boost  /  B brake  /  X probe", 75, 672, 12, MUTED, BODY)
	panel(Rect2(942, 42, 296, 145), Color(0.025, 0.055, 0.065, 0.72))
	text_at("CHASE BRIEF", 962, 70, 12, AMBER, MONO)
	text_at("01  Track the moving tornado", 962, 101, 14, WHITE)
	text_at("02  Dodge airborne debris", 962, 129, 14, WHITE)
	text_at("03  Send 3 probes. Reach the vortex.", 962, 157, 14, WHITE)
	panel(Rect2(942, 202, 296, 247), Color(0.025, 0.055, 0.065, 0.84))
	text_at("LOCAL TOP 5 / FIELD DATA", 961, 230, 12, AMBER, MONO)
	if game.high_scores.is_empty():
		text_at("Your first chase starts the board.", 961, 263, 13, WHITE)
		text_at("Probe sent", 961, 300, 13, MUTED)
		text_at("+1,500", 1149, 300, 13, MINT, MONO)
		text_at("Close dodge", 961, 330, 13, MUTED)
		text_at("+100-500", 1131, 330, 13, MINT, MONO)
		text_at("Tracking / second", 961, 360, 13, MUTED)
		text_at("+20-40", 1149, 360, 13, MINT, MONO)
		text_at("Finish bonus", 961, 402, 13, MUTED)
		text_at("HULL x20", 1130, 402, 12, MINT, MONO)
	else:
		for i in range(game.high_scores.size()):
			var row: Dictionary = game.high_scores[i]
			var y: = 264.0 + i * 36.0
			text_at("%02d" % (i + 1), 961, y, 13, MUTED, MONO)
			text_at("%06d" % int(row.score), 999, y, 19, WHITE, MONO)
			text_at("CLEAR" if row.get("won", false) else "CHASE", 1147, y - 5, 10, MINT if row.get("won", false) else AMBER, MONO)
			var run_label: String = "ASSISTED" if row.get("assisted", false) else ("RETRY" if row.get("retry", false) else "FULL RUN")
			if str(row.get("setup", "stock")) != "stock": run_label += " / " + game.Loadout.option("setup", str(row.setup)).name
			text_at(run_label, 1147, y + 9, 8, MUTED, MONO)
	text_at("BEST DATA   %06d" % game.best, 974, 617, 13, AMBER, MONO)
	text_at("WALLET   %s DATA" % data_amount(int(game.career.banked)), 974, 641, 11, MINT, MONO)
	# Only when a storm link is actually up, so "is my key working" is a
	# question the base menu answers rather than a log file.
	if game.advisor.live(): text_at("STORM LINK   " + game.advisor.describe(), 974, 663, 10, AMBER, MONO)
	var look: String = "STOCK LOOK" if game.Loadout.is_stock_look(game.loadout) else "CUSTOM LOOK"
	panel(Rect2(1030, 526, 208, 24), Color(0.02, 0.045, 0.052, 0.82))
	centered(look + "  /  " + game.Loadout.setup_name(game.loadout) + " SETUP", 1134, 542, 10, MINT if look == "CUSTOM LOOK" else MUTED, MONO)
	if not game.Media.media_complete():
		text_at("BROWSER EDITION  /  IN-GAME CHECKPOINT PREVIEWS" if OS.has_feature("web") else "MEDIA PACK INCOMPLETE  /  COPY assets/audio + assets/cinematics FROM THE FULL PROJECT", 75, 700, 10, AMBER, MONO)

func _draw_dashboard() -> void :
	panel(Rect2(18, 16, 1244, 48), Color(0.025, 0.055, 0.063, 0.76))
	draw_rect(Rect2(35, 29, 3, 22), AMBER)
	text_at("STORM CHASER", 49, 45, 16, WHITE, DISPLAY)
	text_at("0%d / %s" % [game.stage + 1, game.STAGE_NAMES[game.stage]], 299, 44, 12, AMBER, MONO)
	text_at("WIND %03d MPH" % [101 + mini(game.stage,3) * 32 + int(absf(game.wind) * 60)], 625, 44, 11, MUTED, MONO)
	var chapter_progress: float=game.route.orbit_progress() if game.stage==7 else fposmod(game.elapsed,game.STAGE_LENGTH)/game.STAGE_LENGTH
	text_at("LAP %02d%%" % int(chapter_progress*100) if game.stage==7 else "%02d S" % ceili((1.0-chapter_progress)*game.STAGE_LENGTH),796,46,17,WHITE,MONO)
	text_at("DATA %06d" % int(game.score), 923, 44, 13, WHITE, MONO)
	bar(Rect2(20, 68, 1240, 2), (game.stage+chapter_progress)/8.0, AMBER)
	# Thin ticks for the silent mid-stage saves, drawn under the checkpoint pips.
	var spans: int = maxi(1, int(round(game.STAGE_LENGTH / game.SAVE_SPAN)))
	if spans > 1:
		for stage_index in range(8):
			for span in range(1, spans):
				draw_rect(Rect2(20.0 + 1240.0 * (float(stage_index) + float(span) / spans) / 8.0 - 0.5, 65, 1, 8), MUTED)
	for checkpoint_index in range(1,8):
		var x: float = 20.0 + 1240.0 * checkpoint_index / 8.0
		draw_circle(Vector2(x, 69), 3.5, MINT if game.stage_seen >= checkpoint_index else MUTED)

	panel(Rect2(24, 537, 248, 136), Color(0.025, 0.055, 0.063, 0.82))
	text_at("%03d" % int(game.speed), 40, 591, 47, WHITE, MONO)
	text_at("MPH", 149, 591, 12, MUTED, MONO)
	# The six-speed box with its shift interrupt was audio-only; it is the most
	# heavy-truck system in the game and the player could not see any of it.
	var revs: float = clampf((game.powertrain.rpm - 850.0) / 4850.0, 0.0, 1.0)
	var dial: = Vector2(222, 576)
	draw_arc(dial, 24.0, PI * 0.78, PI * 2.22, 32, Color(0.32, 0.45, 0.45, 0.35), 5.0, true)
	draw_arc(dial, 24.0, PI * 0.78, PI * 0.78 + revs * PI * 1.44, 32, AMBER if revs < 0.86 else Color("ff6b4a"), 5.0, true)
	centered("%d" % game.powertrain.gear, dial.x, dial.y + 7, 22, WHITE, MONO)
	centered("GEAR", dial.x, dial.y + 32, 9, MUTED, MONO)
	if game.powertrain.shift_time > 0.0:
		draw_arc(dial, 28.0 + game.powertrain.shift_time * 26.0, 0, TAU, 40, Color(1, 0.82, 0.45, game.powertrain.shift_time / 0.23 * 0.5), 2.0, true)
	if game.combo > 0:
		for i in range(5):
			draw_rect(Rect2(40 + i * 13, 566, 9, 4), MINT if i < game.combo else Color(0.32, 0.45, 0.45, 0.25))
		text_at("x%d" % game.combo, 108, 571, 13, MINT, MONO)
	var drive_label: String = "TURBO" if game.boosting else ("BRAKE" if game.braking else ("NO BOOST" if game.boost_locked else "CRUISE"))
	text_at(drive_label, 40, 609, 11, AMBER if game.boosting else (Color("ff6b4a") if game.boost_locked else MUTED), MONO)
	text_at("GRIP %02d" % int(100.0 * (1.0 - game.aquaplane * 0.7) * game.route.traction), 112, 609, 11, AMBER if game.aquaplane > 0.1 else MUTED, MONO)
	# Damage is scaled, not removed, under calm effects: a hit must still read.
	var punch_gain: float = 0.45 if game.calm_fx else 1.0
	if game.damage_pulse > 0.0:
		var edge: float = 96.0 if game.damage_side < 0.0 else 1184.0
		var a0: float = PI * 0.62 if game.damage_side < 0.0 else -PI * 0.38
		var glow: = Color(1.0, 0.27, 0.18, game.damage_pulse * 0.55 * punch_gain)
		for i in range(4):
			draw_arc(Vector2(edge, 400), 150.0 + i * 26.0, a0, a0 + PI * 0.76, 24, glow, 6.0 - i, true)
	var punch: float = game.damage_pulse * 4.0 * punch_gain
	text_at("HULL", 40, 632, 11, MUTED, MONO)
	bar(Rect2(89 - punch, 623 - punch * 0.5, 143 + punch * 2.0, 5 + punch), game.health / 100.0, Color("ff6b4a").lerp(MINT if game.health > 25 else AMBER, 1.0 - game.damage_pulse))
	text_at("BOOST", 40, 654, 11, MUTED, MONO)
	var boost_rect: = Rect2(89, 645, 143, 5)
	bar(boost_rect, game.boost / game.boost_max, Color("5c6d74") if game.boost_locked else AMBER)
	if game.boost_locked:
		# The lock releases at 28 units, not 28%: show the player that exact mark.
		var gate: float = boost_rect.position.x + boost_rect.size.x * clampf(28.0 / game.boost_max, 0.0, 1.0)
		draw_rect(Rect2(gate - 1.0, 641, 2, 13), MINT)
	panel(Rect2(996, 537, 260, 146), Color(0.025, 0.055, 0.063, 0.82))
	var tracking: bool = game.in_sampling_range()
	var signal_color: = MINT if tracking else AMBER
	draw_circle(Vector2(1017, 559), 3.5, signal_color)
	text_at("TRACKING" if tracking else ("BRAKE" if game.distance < 450 else "BOOST"), 1028, 564, 10, signal_color, MONO)
	text_at("%04d M" % int(game.distance), 1154, 565, 15, WHITE, MONO)
	text_at("PROBES  %02d / 03" % game.probes, 1012, 592, 14, WHITE, MONO)
	bar(Rect2(1012, 612, 228, 4), game.charge / 100.0, MINT)
	if game.message_time > 0.0:
		var width: = MONO.get_string_size(game.message, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 40.0
		panel(Rect2(640 - width * 0.5, 82, width, 37), Color(0.025, 0.055, 0.063, 0.79))
		centered(game.message, 640, 107, 16, AMBER, MONO)
	if game.mode == game.Mode.RUNNING:
		var rec_alpha: float = 0.7 + 0.3 * sin(game.elapsed * 5.0)
		draw_circle(Vector2(559, 676), 3.0, Color(1.0, 0.28, 0.22, rec_alpha))
		text_at("MATEO / STORM CAM", 571, 680, 10, MUTED, MONO)
		var hint: String = "HOLD ARROWS TO STEER   /   BOOST OR BRAKE WITH YOUR OTHER THUMB" if game.touch_controls else ("STICK STEER   A BOOST   B BRAKE   X PROBE   START PAUSE" if game.pad_connected() else "A/D STEER   W BOOST   S BRAKE   SPACE PROBE   C CINEMA   P PAUSE")
		centered(hint, 640, 701, 10, Color(0.68, 0.79, 0.78, 0.8), MONO)
	if game.mateo_caption_time > 0.0 and game.mode == game.Mode.RUNNING:
		var subtitle: String = "MATEO:  " + game.mateo_caption
		var width: float = BODY.get_string_size(subtitle,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x+38
		panel(Rect2(640-width/2,615,width,34),Color(0.015,0.035,0.04,0.84))
		centered(subtitle,640,638,17,WHITE,BODY)
	if game.mode == game.Mode.RUNNING:
		var to_checkpoint: float = (game.stage+1)*game.STAGE_LENGTH-game.elapsed
		if game.stage<2 and to_checkpoint<10.0:
			panel(Rect2(429,126,422,46),Color(0.02,0.04,0.05,0.75))
			centered(("SILO COUNTY" if game.stage==0 else "FREIGHT DISTRICT")+"  /  "+"%02d S" % ceili(to_checkpoint),640,145,12,AMBER,MONO)
			centered("CHECKPOINT FOOTAGE AHEAD",640,162,10,MUTED,MONO)
		elif game.route.active:
			if not _hint_repeats_message():
				panel(Rect2(370,126,540,34),Color(0.02,0.04,0.05,0.75))
				centered(game.route.hint,640,148,11,AMBER,MONO)
			if not game.route.grounded: centered("AIR %.1f M" % game.route.air_height,640,181,16,MINT,MONO)
		elif game.is_breathing(): centered("HOLD YOUR LINE  /  NEXT GUST APPROACHING",640,134,10,MUTED,MONO)
		for piece in game.sky_debris:
			var u: float=piece.age/piece.duration
			if u>0.18 and u<0.59:
				text_at("<" if piece.side<0 else ">",30 if piece.side<0 else 1222,318,30,AMBER,DISPLAY)
				break
	if game.demo: text_at("GAMEPLAY DEMO", 33, 94, 9, AMBER, MONO)

## The route hint panel stays hidden while a notification on the same topic
## (for example AIRBORNE) is already on screen.
func _hint_repeats_message() -> bool:
	if game.message_time <= 0.0: return false
	var topic: String = game.message.get_slice("/", 0).strip_edges()
	return not topic.is_empty() and topic == game.route.hint.get_slice("/", 0).strip_edges()

func dim() -> void :
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.01, 0.025, 0.032, 0.72))

func _draw_pause() -> void :
	dim()
	panel(Rect2(394, 191, 492, 426))
	centered("RADIO SILENCE", 640, 253, 32, WHITE, DISPLAY)
	centered("Your chase is paused.", 640, 289, 16, MUTED)
	centered("T: touch controls   /   M: sound   /   F11: fullscreen", 640, 634, 11, MUTED)

func _draw_upgrade() -> void :
	dim()
	panel(Rect2(254, 181, 778, 363))
	centered("LEVEL %02d CLEARED" % game.stage, 640, 229, 13, AMBER, MONO)
	centered("Tune the truck. The next building is in its path.", 640, 269, 23, WHITE, DISPLAY)
	var titles: = ["FIELD REPAIR", "STORM TIRES", "TURBO TANK"]
	var stats: = ["+40 HULL", "37% LESS DRIFT", "+30 BOOST"]
	var captions: = ["Patch up the interceptor.", "Hold your line in crosswinds.", "A bigger reserve for the chase."]
	for i in range(3):
		var x: = 285.0 + i * 244.0
		panel(Rect2(x, 303, 222, 126), Color(0.04, 0.1, 0.12, 0.9))
		centered(titles[i], x + 111, 333, 14, WHITE, DISPLAY)
		centered(stats[i], x + 111, 370, 18, MINT if i == 0 else AMBER, MONO)
		centered(captions[i], x + 111, 403, 11, MUTED)
	centered("NEXT: " + game.STAGE_NAMES[game.stage] + ("  /  DESTRUCTION PREVIEW + CHECKPOINT" if game.stage<3 else "  /  NEW TERRAIN + CHECKPOINT"), 640, 527, 11, MUTED, MONO)

func _draw_results() -> void :
	dim()
	panel(RESULTS_PANEL)
	centered("TRUCK DISABLED  /  GAME OVER" if game.health <= 0.0 else "FIELD OPERATIONS  /  DEBRIEF", 640, 216, 12, AMBER, MONO)
	centered(game.result_title, 640, 263, 31, WHITE, DISPLAY)

	var words: PackedStringArray = game.result_reason.split(" ")
	var line: = ""
	var y: = 300.0
	for word in words:
		if BODY.get_string_size(line + word, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x > 535:
			centered(line, 640, y, 14, MUTED)
			y += 22
			line = ""
		line += word + " "
	centered(line, 640, y, 14, MUTED)
	centered("%06d" % int(game.score), 640, 402, 52, AMBER, MONO)
	centered("FIELD DATA COLLECTED", 640, 427, 11, MUTED, MONO)
	centered("PROBES %02d   /   NEAR MISSES %02d   /   HULL %03d%%" % [game.probes, game.near_misses, int(game.health)], 640, 461, 12, WHITE, MONO)
	# Above the buttons, which start at y 489. A resumed run that did not beat
	# itself banks nothing, and says so rather than printing a cheerful +0.
	var banked: String = "+%s DATA BANKED" % data_amount(game.banked_this_run) if game.banked_this_run > 0 else "NO NEW DATA BANKED"
	centered(banked, 640, 479, 11, MINT if game.banked_this_run > 0 else MUTED, MONO)
	if game.can_retry_checkpoint():
		centered("RETRY RESTORES LEVEL %02d / %06d DATA / %02d PROBES" % [int(game.checkpoint.stage) + 1, int(game.checkpoint.score), int(game.checkpoint.probes)], 640, 565, 10, MINT, MONO)
	var setup_label: String = "" if str(game.loadout.get("setup", "stock")) == "stock" else game.Loadout.setup_name(game.loadout) + " SETUP  /  "
	centered(("ASSISTED CHASE  /  " if game.run_assisted else "") + setup_label + "PERSONAL BEST   %06d" % game.best + "  /  WALLET   %s DATA" % data_amount(int(game.career.banked)), 640, 591, 11, MUTED, MONO)


func open_settings() -> void:
	if game.mode not in [game.Mode.MENU,game.Mode.PAUSED]: return
	settings_open=true
	rebuild()

func close_settings() -> void:
	settings_open=false
	rebuild()

func settings_rows() -> Array:
	return [
		["STEERING RECOVERY", "Helps recover after puddles, curves and hard landings.", game.steering_assist, game.toggle_option.bind("steering_assist")],
		["EXTRA REACTION TIME", "Debris approaches 22% slower, with more space between waves.", game.relaxed_hazards, game.toggle_option.bind("relaxed_hazards")],
		["LIGHTER GRAPHICS", "Fewer rain and water particles; simpler shadows for laptops.", game.light_graphics, game.toggle_option.bind("light_graphics")],
		["MATEO'S VOICE", "Occasional reactions. Captions remain visible with voice off.", game.mateo_voice, game.toggle_option.bind("mateo_voice")],
		["CALM EFFECTS", "Less camera shake and flashing. The driving challenge stays the same.", game.calm_fx, game.toggle_calm],
		["VIBRATION", "Short impact and puddle pulses on supported devices.", game.haptics_enabled, game.toggle_haptics],
		["AUTOMATIC DODGE FILMS", "Celebrate close calls with a short movie. Every movie can be skipped.", game.auto_dodges, game.dodges.toggle_auto],
		["FULLSCREEN", "Fills the whole screen. Useful on a TV, and reachable without a keyboard.", game.is_fullscreen(), game.toggle_fullscreen],
		["CINEMA VIEW", "Hides the dashboard for a clean view of the storm.", game.cinema_view, game.toggle_cinema],
		["MATEO READS THE CHASE", "Mateo picks his reactions to suit the moment. Needs a storm link; without one he uses his own judgement.", game.storm_ai, game.toggle_option.bind("storm_ai")]
	]

func _build_settings() -> void:
	var rows:=settings_rows()
	for i in range(rows.size()):
		var b:=button("ON" if rows[i][2] else "OFF",Rect2(853,118+i*58, 90,38),_change_setting.bind(i,rows[i][3]),rows[i][2])
		b.tooltip_text=rows[i][1]
		if i==settings_focus: b.grab_focus()
	button("DONE",Rect2(765,646,178,38),close_settings,true)

func _change_setting(index: int, action: Callable) -> void:
	settings_focus=index
	action.call()

func _draw_settings() -> void:
	dim()
	panel(Rect2(302,30,677,662),Color(0.018,0.042,0.05,0.98))
	text_at("MAKE THE CHASE YOURS",334,78,26,WHITE,DISPLAY)
	text_at("All checkpoint films can be earned with either driving setting.",335,103,13,MUTED,BODY)
	var rows:=settings_rows()
	for i in range(rows.size()):
		var y:=136+i*58
		text_at(rows[i][0],335,y,13,AMBER,DISPLAY)
		text_at(rows[i][1],335,y+20,11,MUTED,BODY)
		if i<rows.size()-1: draw_line(Vector2(335,y+40),Vector2(943,y+40),EDGE,1)
	text_at("Changes save automatically.",335,672,12,MUTED,BODY)
