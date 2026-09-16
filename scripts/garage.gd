extends Control
## Mateo's Garage: a pre-chase screen over the live 3D truck.
##
## Keyboard: Up/Down (W/S) select, Left/Right (A/D) change, Q/E orbit, R stock
## look, Enter/Space start, Escape back. Controller: D-pad or left stick, A start,
## B back, Start start, LB/RB orbit. Mouse/touch: click rows and arrows, drag the
## truck to orbit. All buttons are mouse-only so directional input never fights
## focus navigation.

const Loadout := preload("res://scripts/loadout.gd")
const AMBER := Color("f4bc63")
const WHITE := Color("ecf0e9")
const MINT := Color("84dfb9")
const MUTED := Color("94aaa9")
const RED := Color("e8866f")
const PANEL := Rect2(812, 24, 444, 672)
const ROW_TOP := 150.0
const ROW_HEIGHT := 64.0
const SETUP_GAP := 16.0

var game
var active := false
var age := 0.0
var selected := 0
var orbit := 0.0
var orbit_velocity := 0.0
var toast := ""
var toast_time := 0.0
var drag_area: Control
var controls: Array[Control] = []

func _ready() -> void:
	size = Vector2(1280, 720)
	z_index = 25
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func open() -> void:
	active = true
	age = 0.0
	orbit = 0.0
	orbit_velocity = 0.0
	toast = ""
	_rebuild()
	show()

func close() -> void:
	active = false
	for c in controls:
		c.hide()
		c.queue_free()
	controls.clear()
	drag_area = null
	hide()

func row_rect(index: int) -> Rect2:
	var y := ROW_TOP + index * ROW_HEIGHT + (SETUP_GAP if index == Loadout.SLOTS.size() - 1 else 0.0)
	return Rect2(830, y, 408, ROW_HEIGHT - 6.0)

func _rebuild() -> void:
	for c in controls:
		c.hide()
		c.queue_free()
	controls.clear()
	drag_area = Control.new()
	drag_area.position = Vector2.ZERO
	drag_area.size = Vector2(PANEL.position.x - 8, 640)
	drag_area.mouse_filter = Control.MOUSE_FILTER_STOP
	drag_area.gui_input.connect(_drag_input)
	add_child(drag_area)
	controls.append(drag_area)
	for i in range(Loadout.SLOTS.size()):
		var r := row_rect(i)
		var pick := _button("", Rect2(r.position, Vector2(r.size.x - 96, r.size.y)), select.bind(i), true)
		pick.tooltip_text = Loadout.SLOT_TITLES[Loadout.SLOTS[i]]
		_button("<", Rect2(r.end.x - 90, r.position.y + 12, 40, 34), _step_row.bind(i, -1))
		_button(">", Rect2(r.end.x - 44, r.position.y + 12, 40, 34), _step_row.bind(i, 1))
	_button("STOCK LOOK", Rect2(830, 632, 124, 44), stock_look)
	_button("BACK", Rect2(962, 632, 96, 44), back)
	_button("RESUME   >" if game.can_retry_checkpoint() else "START   >", Rect2(1066, 632, 172, 44), start, true)
	queue_redraw()

func _button(label: String, r: Rect2, action: Callable, primary_or_clear: bool = false) -> Button:
	var b := Button.new()
	b.text = label
	b.position = r.position
	b.size = r.size
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var clear := primary_or_clear and label.is_empty()
	var primary := primary_or_clear and not label.is_empty()
	b.add_theme_font_override("font", game.hud.DISPLAY)
	b.add_theme_font_size_override("font_size", 15)
	var ink := Color("15262b") if primary else WHITE
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(key, ink)
	var fill := Color.TRANSPARENT if clear else (AMBER if primary else Color("122a30"))
	b.add_theme_stylebox_override("normal", game.hud.style(fill, Color.TRANSPARENT if clear else (AMBER if primary else game.hud.EDGE)))
	b.add_theme_stylebox_override("hover", game.hud.style(Color(0.96, 0.74, 0.39, 0.06) if clear else (Color("ffd18a") if primary else Color("25424a")), AMBER))
	b.add_theme_stylebox_override("pressed", game.hud.style(Color(0.96, 0.74, 0.39, 0.1) if clear else (Color("dc9b45") if primary else Color("0c2025")), AMBER))
	b.pressed.connect(action)
	add_child(b)
	controls.append(b)
	return b

func select(index: int) -> void:
	selected = clampi(index, 0, Loadout.SLOTS.size() - 1)
	game.play_sound("click")
	queue_redraw()

func _step_row(index: int, step: int) -> void:
	selected = index
	change(step)

func move(step: int) -> void:
	selected = posmod(selected + step, Loadout.SLOTS.size())
	game.play_sound("click")
	queue_redraw()

func change(step: int) -> void:
	var slot: String = Loadout.SLOTS[selected]
	game.set_loadout(Loadout.cycle(game.loadout, slot, step))
	game.play_sound("click")
	_notify(Loadout.SLOT_TITLES[slot] + "  /  " + str(Loadout.option(slot, game.loadout[slot]).name))

func stock_look() -> void:
	game.set_loadout(Loadout.with_stock_look(game.loadout))
	game.play_sound("pickup")
	_notify("APPROVED STOCK LOOK RESTORED")

func start() -> void:
	if not active: return
	game.leave_garage(true)

func back() -> void:
	if not active: return
	game.leave_garage(false)

func _notify(text: String) -> void:
	toast = text
	toast_time = 2.2
	queue_redraw()

func handle_input(event: InputEvent) -> void:
	var handled := true
	if event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_W, KEY_UP: move(-1)
			KEY_S, KEY_DOWN: move(1)
			KEY_A, KEY_LEFT: change(-1)
			KEY_D, KEY_RIGHT: change(1)
			KEY_Q: orbit_velocity = -1.6
			KEY_E: orbit_velocity = 1.6
			KEY_R:
				if not event.echo: stock_look()
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				if not event.echo: start()
			KEY_ESCAPE, KEY_P, KEY_BACKSPACE:
				if not event.echo: back()
			KEY_M, KEY_T, KEY_F11:
				pass # Sound, touch and fullscreen are handled by the game first.
			_:
				handled = false
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_UP: move(-1)
			JOY_BUTTON_DPAD_DOWN: move(1)
			JOY_BUTTON_DPAD_LEFT: change(-1)
			JOY_BUTTON_DPAD_RIGHT: change(1)
			JOY_BUTTON_LEFT_SHOULDER: orbit_velocity = -1.6
			JOY_BUTTON_RIGHT_SHOULDER: orbit_velocity = 1.6
			JOY_BUTTON_Y: stock_look()
			JOY_BUTTON_A, JOY_BUTTON_START: start()
			JOY_BUTTON_B, JOY_BUTTON_BACK: back()
			_: handled = false
	elif event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_LEFT_Y and absf(event.axis_value) > 0.6 and _stick_ready(event.axis):
			move(1 if event.axis_value > 0.0 else -1)
		elif event.axis == JOY_AXIS_LEFT_X and absf(event.axis_value) > 0.6 and _stick_ready(event.axis):
			change(1 if event.axis_value > 0.0 else -1)
		elif event.axis == JOY_AXIS_RIGHT_X and absf(event.axis_value) > 0.25:
			orbit_velocity = event.axis_value * 1.8
		else:
			handled = false
	else:
		handled = false
	if handled: get_viewport().set_input_as_handled()

var _stick_latch := {}
func _stick_ready(axis: int) -> bool:
	# One step per stick push; it must return near centre before repeating.
	if _stick_latch.get(axis, false): return false
	_stick_latch[axis] = true
	return true

func _drag_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		orbit -= event.relative.x * 0.008
	elif event is InputEventScreenDrag:
		orbit -= event.relative.x * 0.008

func _process(dt: float) -> void:
	if not active: return
	age += dt
	toast_time = maxf(0.0, toast_time - dt)
	orbit += orbit_velocity * dt
	orbit_velocity = move_toward(orbit_velocity, 0.0, dt * 3.5)
	for axis in _stick_latch.keys():
		var pads := Input.get_connected_joypads()
		if pads.is_empty() or absf(Input.get_joy_axis(pads[0], axis)) < 0.3: _stick_latch.erase(axis)
	if is_instance_valid(game.world) and is_instance_valid(game.world.truck):
		game.world.truck.kit.step(dt)
	queue_redraw()

## Orbiting preview camera; the truck stays parked on the wet highway.
func apply_view() -> void:
	if not active: return
	var w = game.world
	var truck: Node3D = w.truck
	var yaw := -2.45 + age * 0.16 + orbit
	var radius := 8.6
	var target: Vector3 = truck.position + Vector3(0, 1.2, 0)
	var eye: Vector3 = target + Vector3(sin(yaw) * radius, 1.35 + sin(age * 0.23) * 0.25, cos(yaw) * radius)
	w.camera.position = eye
	w.camera.fov = 46.0
	w.camera.look_at(target, Vector3.UP)
	# Shift the framing so the truck sits left of the garage panel.
	w.camera.look_at(target + w.camera.global_transform.basis.x * 2.35, Vector3.UP)
	w.sky.rotation = Vector3(0, w.camera.rotation.y, 0)
	w.sky.position = w.camera.position + Vector3(0, 474, -600).rotated(Vector3.UP, w.camera.rotation.y)
	w.storm_material.set_shader_parameter("clock", (game.elapsed + age) * 1.45)
	w.mateo.garage_pose(game.clock)

func _wrap(value: String, font: Font, font_size: int, width: float) -> PackedStringArray:
	var lines := PackedStringArray()
	var line := ""
	for word in value.split(" "):
		var candidate := word if line.is_empty() else line + " " + word
		if not line.is_empty() and font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
			lines.append(line)
			line = word
		else:
			line = candidate
	if not line.is_empty(): lines.append(line)
	return lines

func _text(value: String, x: float, y: float, font_size: int, color: Color, font: Font) -> void:
	draw_string(font, Vector2(x, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	if not active: return
	var hud = game.hud
	# Soft falloff behind the panel keeps the text readable over the storm.
	for i in range(40):
		draw_rect(Rect2(700 + i * 15, 0, 15, 720), Color(0.012, 0.03, 0.036, 0.62 * float(i) / 40.0))
	draw_style_box(hud.style(Color(0.018, 0.042, 0.05, 0.9), hud.EDGE, 12), PANEL)
	_text("BASE  /  PRE-CHASE BAY", 846, 58, 12, AMBER, hud.MONO)
	_text("MATEO'S GARAGE", 844, 98, 30, WHITE, hud.DISPLAY)
	_text("Parts change the look only. Setup is a separate trade-off.", 846, 126, 13, MUTED, hud.BODY)
	for i in range(Loadout.SLOTS.size()):
		var slot: String = Loadout.SLOTS[i]
		var r := row_rect(i)
		if i == Loadout.SLOTS.size() - 1:
			draw_line(Vector2(846, r.position.y - 9), Vector2(1222, r.position.y - 9), hud.EDGE, 1.0)
		var focused := i == selected
		draw_style_box(hud.style(Color(0.96, 0.74, 0.39, 0.07) if focused else Color(0.04, 0.09, 0.1, 0.55), AMBER if focused else Color.TRANSPARENT, 7), r)
		var entry: Dictionary = Loadout.option(slot, str(game.loadout.get(slot, "stock")))
		var count := Loadout.options(slot).size()
		var index := Loadout.index_of(slot, entry.id)
		_text(Loadout.SLOT_TITLES[slot], r.position.x + 16, r.position.y + 22, 11, AMBER if focused else MUTED, hud.MONO)
		_text("%d/%d" % [index + 1, count], r.end.x - 136, r.position.y + 22, 10, MUTED, hud.MONO)
		_text(str(entry.name), r.position.x + 16, r.position.y + 46, 17, WHITE, hud.DISPLAY)
		if entry.id == "stock":
			var name_width: float = hud.DISPLAY.get_string_size(str(entry.name), HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
			_text("APPROVED" if slot != "setup" else "ORIGINAL TUNE", r.position.x + 26 + name_width, r.position.y + 45, 9, MINT, hud.MONO)
	# Details for the focused row.
	var focus_slot: String = Loadout.SLOTS[selected]
	var detail: Dictionary = Loadout.option(focus_slot, str(game.loadout.get(focus_slot, "stock")))
	var info_y := row_rect(Loadout.SLOTS.size() - 1).end.y + 22
	var lines := _wrap(str(detail.info), hud.BODY, 13, 392.0)
	for i in range(mini(lines.size(), 2)):
		_text(lines[i], 846, info_y + i * 18, 13, WHITE, hud.BODY)
	var stat_y := info_y + mini(lines.size(), 2) * 18 + 4
	if focus_slot == "setup":
		_text(str(detail.effects), 846, stat_y, 11, MINT if detail.id == "stock" else AMBER, hud.MONO)
	else:
		_text("CHASE SETUP  /  " + Loadout.setup_name(game.loadout) + ("  /  ORIGINAL TUNE" if game.loadout.setup == "stock" else ""), 846, stat_y, 10, MUTED, hud.MONO)
	# Left-side labels over the live preview.
	_text("INTERCEPTOR  /  LIVE PREVIEW", 40, 58, 12, AMBER, hud.MONO)
	_text("Stock look" if Loadout.is_stock_look(game.loadout) else "Custom look", 40, 84, 18, WHITE, hud.BODY)
	_text("UP / DOWN SELECT     LEFT / RIGHT CHANGE     Q / E  OR DRAG  ORBIT     R STOCK LOOK", 40, 672, 11, Color(0.68, 0.79, 0.78, 0.85), hud.MONO)
	_text("ENTER  START     ESC  BACK TO BASE     CONTROLLER: D-PAD, A START, B BACK, LB / RB ORBIT", 40, 692, 11, Color(0.68, 0.79, 0.78, 0.85), hud.MONO)
	if toast_time > 0.0:
		var width: float = hud.MONO.get_string_size(toast, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 40.0
		var alpha := clampf(toast_time / 0.3, 0.0, 1.0)
		draw_style_box(hud.style(Color(0.025, 0.055, 0.063, 0.82 * alpha), Color(0.49, 0.66, 0.64, 0.25 * alpha), 12), Rect2(400 - width * 0.5, 110, width, 33))
		_text(toast, 400 - (width - 40.0) * 0.5, 132, 12, Color(AMBER, alpha), hud.MONO)
