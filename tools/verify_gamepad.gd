extends SceneTree
## Controller coverage. Menu navigation is handled by the Viewport's GUI layer,
## not by main.gd's _unhandled_input, so these checks push real events through
## get_viewport().push_input() and assert on the focus owner. A test that only
## called game._unhandled_input() would prove nothing about navigation.
const MediaPack = preload("res://scripts/media.gd")
var checks := 0
var failures := 0
var game

func _initialize() -> void: call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1
	print("PASS: " if value else "FAIL: ", label)

func pad_button(index: int, pressed: bool = true) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = pressed
	return event

## Presses a pad button the way a controller does, through the GUI layer.
func press(index: int) -> void:
	Input.parse_input_event(pad_button(index, true))
	await process_frame
	Input.parse_input_event(pad_button(index, false))
	await process_frame

func focus_owner() -> Control:
	return root.gui_get_focus_owner()

## Every action an InputMap action is bound to, split by event type.
func action_has_pad(action: String) -> bool:
	if not InputMap.has_action(action): return false
	return InputMap.action_get_events(action).any(func(e): return e is InputEventJoypadButton or e is InputEventJoypadMotion)

func action_has_key(action: String) -> bool:
	if not InputMap.has_action(action): return false
	return InputMap.action_get_events(action).any(func(e): return e is InputEventKey)

func settle() -> void:
	for i in range(3): await process_frame

func run() -> void:
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"
	game = load("res://main.tscn").instantiate()
	game.settings_path = "user://gamepad-test-isolated.cfg"
	root.add_child(game)
	await settle()
	game.save_enabled = false

	# --- bindings ---
	for action in ["left", "right", "boost", "brake", "probe", "pause_game", "mute"]:
		check(action_has_pad(action), "%s is reachable from a controller" % action)
	check(action_has_key("mute"), "mute is still reachable from the keyboard")
	check(InputMap.action_get_events("boost").any(func(e): return e is InputEventJoypadMotion and e.axis == JOY_AXIS_TRIGGER_RIGHT),
		"the right trigger accelerates, not only the A button")

	# --- mute is global, so no screen has to hand-roll its own key check ---
	var muted_before: bool = game.muted
	game._unhandled_input(pad_button(JOY_BUTTON_RIGHT_STICK))
	check(game.muted != muted_before, "the pad mutes from the chase")
	game.mode = game.Mode.CHECKPOINT
	game._unhandled_input(pad_button(JOY_BUTTON_RIGHT_STICK))
	check(game.muted == muted_before, "the pad still mutes during a checkpoint cinematic")
	game.mode = game.Mode.MENU
	game.hud.rebuild()
	await settle()

	# --- every screen a controller can reach must leave something focused ---
	check(focus_owner() != null, "the base menu seeds focus for a controller")

	var first: Control = focus_owner()
	Input.parse_input_event(pad_button(JOY_BUTTON_DPAD_RIGHT))
	await settle()
	Input.parse_input_event(pad_button(JOY_BUTTON_DPAD_RIGHT, false))
	await settle()
	check(focus_owner() != null, "focus survives a D-pad press on the menu")

	game.hud.open_settings()
	await settle()
	check(focus_owner() != null, "the settings panel seeds focus")
	var rows: Array = game.hud.settings_rows()
	check(rows.size() == 9, "settings expose nine rows including the keyboard-only toggles")
	check(rows.any(func(r): return str(r[0]) == "FULLSCREEN"), "fullscreen is reachable without a keyboard")
	check(rows.any(func(r): return str(r[0]) == "CINEMA VIEW"), "cinema view is reachable without a keyboard")
	# Every row must fit inside the 720p panel, buttons included.
	var last_button_bottom: float = 118.0 + (rows.size() - 1) * 58.0 + 38.0
	check(last_button_bottom <= 692.0, "the last settings row fits inside the panel")
	game.hud.close_settings()
	await settle()

	# --- the gallery is the screen that could strand a controller ---
	game.dodges.show_gallery()
	await settle()
	check(game.dodges.visible, "the gallery opens")
	check(focus_owner() != null, "the gallery seeds focus")
	# The close button is the fallback target when every tile and page button is
	# disabled. Today two pages guarantee a page button takes focus, so assert
	# the fallback's precondition rather than pretend to exercise a state the
	# current catalog size cannot reach.
	var exits: Array = game.dodges.get_children().filter(func(c): return c is Button and not c.disabled and c.focus_mode == Control.FOCUS_ALL)
	check(not exits.is_empty(), "the gallery always offers at least one focusable way out")
	game.dodges.close_gallery()
	await settle()

	# --- the pause and results screens ---
	game.start_chase()
	await settle()
	game.pause_chase()
	await settle()
	check(focus_owner() != null, "the pause menu seeds focus")
	game.resume_chase()
	await settle()
	game.finish(false, "gamepad coverage check")
	await settle()
	check(game.mode == game.Mode.RESULTS, "the run ends on the results screen")
	check(focus_owner() != null, "the results screen seeds focus")

	# --- the upgrade screen, which is the only mid-run menu ---
	game.start_chase()
	await settle()
	game.mode = game.Mode.UPGRADE
	game.hud.rebuild()
	await settle()
	check(focus_owner() != null, "the upgrade screen seeds focus")

	print("GAMEPAD_TESTS ", checks, " checks; ", failures, " failures")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
