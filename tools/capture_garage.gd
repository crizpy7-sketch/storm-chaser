extends SceneTree
## Mateo Garage review stills from actual rendering. Set STORM_CAPTURE_DIR.
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
func look(accent: String, wheels: String, roof: String, armor: String, trim: String, setup: String = "stock") -> void:
	game.set_loadout({"accent": accent, "wheels": wheels, "roof": roof, "armor": armor, "trim": trim, "setup": setup})
func run() -> void:
	out = OS.get_environment("STORM_CAPTURE_DIR")
	if out.is_empty(): out = ProjectSettings.globalize_path("user://")
	game = load("res://main.tscn").instantiate()
	game.settings_path = "user://garage-capture.cfg"
	root.add_child(game)
	await frames(2)
	game.save_enabled = false
	game.loadout = game.Loadout.default_loadout()
	await shot("G0-menu")
	game.open_garage()
	game.garage.age = 1.5
	await shot("G1-garage-stock")
	look("storm_white", "bronze_beadlock", "light_bar", "bull_bar", "lift_kit")
	game.garage.orbit = 0.95
	game.garage.selected = 3
	await shot("G2-white-bullbar-lift")
	look("rescue_red", "polished_alloy", "weather_mast", "winch", "rally")
	game.garage.orbit = 1.75
	game.garage.selected = 2
	await shot("G3-red-mast-winch")
	look("glacier_teal", "stealth_black", "doppler_dome", "ram_plate", "desert_runner", "armored")
	game.garage.orbit = 3.4
	game.garage.selected = 5
	await shot("G4-teal-dome-ram-armored")
	game.leave_garage(false)
	game.dodges.show_gallery()
	await shot("G5-gallery-loadout")
	game.dodges.close_gallery()
	game.rng.seed = 72611
	game.start_chase()
	game.invulnerable = 99.0
	await frames(30)
	await shot("G6-chase-custom")
	game.stage = 7; game.stage_seen = 7; game.elapsed = 214.0; game.route.enter(7); game.route.progress = 300.0
	game.speed = game.CRUISE_SPEEDS[7]; game.debris.clear(); game.world.reset_motion(); game.hud.rebuild()
	await frames(20)
	await shot("G7-vortex-orbit-custom")
	game.return_to_menu()
	await shot("G8-menu-custom")
	print("GARAGE_CAPTURE_COMPLETE")
	game.queue_free(); await process_frame; quit(0)
