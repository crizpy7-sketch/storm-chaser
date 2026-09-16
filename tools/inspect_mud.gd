extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.settings_path="user://mud-review-isolated.cfg"
	root.add_child(game)
	await process_frame
	game.demo=true;game.save_enabled=false;game.auto_dodges=false
	game.set_process(false);game.world.set_process(false);game.world.mateo.set_process(false)
	game.start_chase();game.stage=4;game.stage_seen=4;game.elapsed=120
	game.route.enter(4);game.speed=122
	for target in [110.0,139.0,150.0,166.0,192.0,320.0]:
		for i in range(1200):
			if game.route.progress>=target: break
			game._simulate(1.0/60.0)
			game.world.water_fx.step(1.0/60.0)
		game.world.show();game.world.space.show()
		game.world.camera_pan=game.player_x*3.6
		game.world.truck.step(.016)
		game.world._update_view(0)
		game.hud.queue_redraw()
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("../review/mud-%d.png"%int(target))
		print("MUD_REVIEW progress=",game.route.progress," slide=",game.route.shortcut_slide," yaw=",game.truck_yaw," speed=",game.speed," lane=",game.player_x)
	game.queue_free();await process_frame;quit()
