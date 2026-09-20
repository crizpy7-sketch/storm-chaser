extends SceneTree
## Send independent screen contacts through the viewport input pipeline.
var game
var checks := 0
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ", label)

func touch(index: int, point: Vector2, pressed: bool = true, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index; event.position = point; event.pressed = pressed; event.canceled = canceled
	root.push_input(event, true)

func drag(index: int, point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index; event.position = point
	root.push_input(event, true)

func clear_holds() -> bool:
	return not game.touch_left and not game.touch_right and not game.touch_boost and not game.touch_brake and game.hud.touch_points.is_empty() and game.hud.touch_taps.is_empty()

func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.settings_path = "user://touch-test-isolated.cfg"
	root.add_child(game)
	await process_frame
	game.save_enabled = false
	game.set_process(false); game.world.set_process(false)
	game.start_chase()
	game.touch_controls = false
	game.hud.rebuild()
	var left := Vector2(80, 464)
	var right := Vector2(204, 464)
	var brake := Vector2(1072, 464)
	var boost := Vector2(1196, 464)
	var road := Vector2(640, 360)
	touch(0, left)
	check(game.touch_controls and game.touch_left, "the first real touch enables controls and steers without a keyboard")
	touch(1, boost)
	game._simulate(1.0 / 60.0)
	check(game.steer < 0.0 and game.boosting, "two fingers steer and boost simultaneously in the driving simulation")
	game.charge = 100.0; game.distance = 800.0
	game.hud._process(0.0)
	var probe_point: Vector2 = game.hud.probe_button.get_global_rect().get_center()
	touch(20, probe_point); touch(20, probe_point, false)
	check(game.probes == 1 and game.touch_left and game.touch_boost, "a third finger transmits a probe while steering and boosting")
	touch(0, road, false)
	check(not game.touch_left and game.touch_boost, "releasing steering outside its button leaves the other finger boosting")
	drag(1, brake)
	game._simulate(1.0 / 60.0)
	check(game.braking and not game.boosting and game.touch_brake and not game.touch_boost, "a held finger can slide from boost to brake")
	drag(1, road)
	check(not game.touch_brake and not game.touch_boost, "dragging off the pedals releases their holds")
	drag(1, boost)
	check(game.touch_boost, "the same held finger can slide back onto a pedal")
	touch(1, boost, true, true)
	check(clear_holds(), "a canceled screen contact releases its hold even if marked pressed")
	touch(2, left); touch(3, left)
	touch(2, left, false)
	check(game.touch_left, "two fingers on one arrow keep steering until both release")
	drag(3, right)
	check(game.touch_right and not game.touch_left, "steering slides between arrows without leaving the old arrow held")
	touch(3, right, false)
	touch(4, road); drag(4, boost)
	check(clear_holds(), "a touch that began on the road cannot turn into an accidental pedal hold")
	touch(4, road, false)
	touch(5, left); touch(6, boost)
	var pause_point := Vector2(1207, 128)
	touch(21, pause_point); touch(21, pause_point, false)
	check(game.mode == game.Mode.PAUSED and clear_holds(), "pausing clears every finger and driving hold")
	game.resume_chase()
	var sound_point: Vector2 = game.hud.audio_button.get_global_rect().get_center()
	var muted: bool = game.muted
	touch(22, sound_point); touch(22, sound_point, true, true)
	check(game.muted == muted and clear_holds(), "canceling a sound-button tap leaves its setting unchanged")
	drag(5, left); drag(6, boost)
	check(clear_holds(), "fingers held across pause cannot reactivate until pressed again")
	touch(7, boost)
	game.hud.rebuild()
	check(clear_holds(), "rebuilding the HUD cannot leave a removed control held")
	touch(8, right); touch(9, brake)
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.mode == game.Mode.PAUSED and clear_holds(), "switching apps pauses and clears all touch contacts")
	game.resume_chase()
	touch(10, left)
	game.return_to_menu()
	check(clear_holds(), "returning to base clears touch input")
	game.start_chase()
	var minimum_size := true
	for control in game.hud.touch_buttons.values():
		minimum_size = minimum_size and control.size.x >= 80.0 and control.size.y >= 80.0
	check(minimum_size and game.hud.probe_button.size.y >= 80.0, "driving and probe targets are at least 80 canvas pixels high")
	game.cinema_view = true
	game.hud._process(0.0)
	check(game.hud.visible, "cinema mode keeps mobile driving controls visible")
	game.cinema_view = false
	touch(11, left)
	var mouse := InputEventMouseButton.new()
	mouse.device = -1; mouse.button_index = MOUSE_BUTTON_LEFT; mouse.position = left; mouse.pressed = true
	root.push_input(mouse, true)
	touch(11, left, false)
	check(clear_holds(), "an emulated mouse event cannot leave a second hold after a finger releases")
	mouse.device = 0; mouse.position = boost
	root.push_input(mouse, true)
	check(game.touch_boost, "desktop mouse users can still hold the optional driving controls")
	mouse.pressed = false; mouse.position = road
	root.push_input(mouse, true)
	check(clear_holds(), "desktop mouse release outside the control clears its hold")
	game.touch_controls = false
	game.hud.rebuild()
	Input.action_press("left"); Input.action_press("boost")
	game._simulate(1.0 / 60.0)
	check(game.steer < 0.0 and game.boosting and game.hud.touch_buttons.is_empty(), "desktop keyboard driving remains unchanged with touch controls disabled")
	Input.action_release("left"); Input.action_release("boost")
	print("TOUCH_TESTS ", checks, " checks; ", failures, " failures")
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
