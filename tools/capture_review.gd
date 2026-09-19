extends SceneTree
## Review stills from actual game rendering: menu, each terrain type, the tornado
## orbit, pause/upgrade/results overlays. Set STORM_CAPTURE_DIR to an existing folder.
var game
var out := ""
func _initialize() -> void: call_deferred("run")

func frames(n: int) -> void:
	for i in range(n): await process_frame
	await RenderingServer.frame_post_draw

func shot(label: String) -> void:
	await frames(2)
	root.get_texture().get_image().save_png(out + "/" + label + ".png")
	print("SHOT ", label)

func select(level: int, progress: float = 0.0) -> void:
	game.stage = level; game.stage_seen = level; game.elapsed = level * game.STAGE_LENGTH + 4.0
	game.mode = game.Mode.RUNNING; game.route.enter(level)
	game.route.progress = progress; game.world.travel = progress
	game.speed = game.CRUISE_SPEEDS[level]; game.powertrain.reset(game.speed)
	game.player_x = 0; game.velocity_x = 0; game._reset_water()
	game.debris.clear(); game.puddles.clear(); game.sky_debris.clear()
	game.health = 100; game.boost = 100; game.invulnerable = 99.0
	game.world.reset_motion(); game.hud.rebuild()

func run() -> void:
	out = OS.get_environment("STORM_CAPTURE_DIR")
	if out.is_empty(): out = ProjectSettings.globalize_path("user://")
	game = load("res://main.tscn").instantiate()
	game.settings_path = "user://review-capture.cfg"
	root.add_child(game)
	await frames(3)
	game.save_enabled = false; game.auto_dodges = false
	await shot("00-menu")
	game.rng.seed = 72611
	game.start_chase()
	game.invulnerable = 99.0
	await frames(40)
	await shot("01-highway")
	game._spawn_item(0, -0.25); game.debris.back().z = 0.72
	game._spawn_item(1, 0.76); game.debris.back().z = 0.55
	game._spawn_puddle(0.3); game.puddles.back().z = -30.0
	await shot("02-highway-hazards")
	select(1); game._spawn_sky_piece(0, 1.0); game.sky_debris[0].age = 1.6
	await frames(10)
	await shot("03-barn-semi")
	select(3, 120.0); Input.action_press("right")
	await frames(30)
	await shot("04-crosswind-curve")
	Input.action_release("right")
	select(4, 95.0)
	await frames(20)
	await shot("05-shortcut-junction")
	select(4, 175.0)
	await frames(20)
	await shot("06-shortcut-drift")
	select(5, 100.0)
	await frames(25)
	await shot("07-ridgeline")
	select(6, 140.0)
	await frames(25)
	await shot("08-wild-hills")
	select(7, 60.0)
	await frames(20)
	await shot("09-vortex-approach")
	select(7, 300.0)
	await frames(20)
	await shot("10-vortex-orbit")
	game.pause_chase()
	await shot("11-pause")
	game.resume_chase()
	select(0); game.elapsed = game.STAGE_LENGTH; game.stage_seen = 0; game.stage = 1
	game.mode = game.Mode.UPGRADE; game.hud.rebuild()
	await shot("12-upgrade")
	game.mode = game.Mode.RUNNING; game.finish(false, "The tornado escaped radar range. Use boost to close the gap.")
	await shot("13-results")
	game.return_to_menu(); game.dodges.show_gallery()
	await shot("14-gallery")
	print("REVIEW_CAPTURE_COMPLETE")
	game.queue_free(); await process_frame; quit(0)
