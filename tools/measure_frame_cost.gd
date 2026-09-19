extends SceneTree
## Prints the per-frame GDScript cost of the driving simulation and the 3D view
## update for each terrain type. Run headless on the target machine:
##   godot --headless --path . --script res://tools/measure_frame_cost.gd
## Numbers exclude GPU rendering; compare levels and builds on the same machine.
var game

func _initialize() -> void: call_deferred("run")

func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.settings_path = "user://frame-cost.cfg"
	root.add_child(game)
	await process_frame
	game.save_enabled = false
	game.set_process(false); game.world.set_process(false)
	for level in [0, 3, 4, 5, 6, 7]:
		game.start_chase()
		game.set_process(false)
		game.stage = level; game.stage_seen = level; game.elapsed = level * game.STAGE_LENGTH + 1.0
		game.route.enter(level); game.speed = game.CRUISE_SPEEDS[level]; game.powertrain.reset(game.speed)
		game.world.reset_motion()
		var simulate := 0
		var view := 0
		var frames := 240
		for i in range(frames):
			# Keep a representative drive: stay near the lane centre with a full hull.
			game.invulnerable = 99.0
			game.health = 100.0
			Input.action_release("left"); Input.action_release("right")
			var axis := clampf(-game.player_x * 4.0 - game.route.drift * 0.8, -1.0, 1.0)
			if axis > 0.05: Input.action_press("right", axis)
			elif axis < -0.05: Input.action_press("left", -axis)
			var t0 := Time.get_ticks_usec()
			game._simulate(1.0 / 60.0)
			var t1 := Time.get_ticks_usec()
			game.world.travel = game.route.progress if game.route.active else game.world.travel + game.speed * 0.25 / 60.0
			game.world._update_view(1.0 / 60.0)
			simulate += t1 - t0
			view += Time.get_ticks_usec() - t1
		Input.action_release("left"); Input.action_release("right")
		print("FRAME_COST level %d %-18s simulate %5.2f ms   view update %5.2f ms" % [level + 1, game.STAGE_NAMES[level], simulate / 1000.0 / frames, view / 1000.0 / frames])
	game.queue_free(); await process_frame; quit(0)
