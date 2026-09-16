extends SceneTree
var game
func _initialize() -> void:call_deferred("run")
func run() -> void:
	game=load("res://main.tscn").instantiate();game.settings_path="user://landscape-preview.cfg"
	root.add_child(game);await process_frame
	game.save_enabled=false;game.auto_dodges=false;game.start_chase()
	game.set_process(false);game.world.set_process(false)
	for shot in range(3):
		var level: int= [1,3,5][shot]
		game.stage=level;game.stage_seen=level;game.elapsed=level * game.STAGE_LENGTH+4.0
		game.mode=game.Mode.RUNNING;game.route.enter(level)
		game.route.progress=[115.0,90.0,185.0][shot];game.world.travel=game.route.progress
		game.player_x=0;game.velocity_x=0;game.speed=110
		game.debris.clear();game.sky_debris.clear();game.puddles.clear()
		if shot==1:
			game._spawn_sky_piece(0,1.0);game.sky_debris[0].age=2.50
		game.world._update_view(0.0);game.hud.rebuild()
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("STORM_CAPTURE_DIR")+"/Landscape-%d.png"%shot)
	print("LANDSCAPE_STILLS_COMPLETE")
	game.queue_free();await process_frame;quit(0)
