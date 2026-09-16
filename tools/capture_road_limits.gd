extends SceneTree
var game
func _initialize() -> void:call_deferred("run")
func run() -> void:
	game=load("res://main.tscn").instantiate();game.settings_path="user://road-edge-capture.cfg"
	root.add_child(game);await process_frame
	game.save_enabled=false;game.start_chase();game.set_process(false);game.world.set_process(false)
	game.stage=3;game.stage_seen=3;game.elapsed=92;game.route.enter(3);game.route.progress=70
	game.calm_fx=true
	for side in [-1.0,1.0]:
		game.player_x=game.road_steering_limit()*side;game.truck_yaw=-.13*side
		game.world.camera_pan=game.player_x*3.6;game.world._update_view(0);game.hud.rebuild()
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("STORM_CAPTURE_DIR")+"/Road-limit-"+("left" if side<0 else "right")+".png")
	print("ROAD_LIMIT_VISUAL_CAPTURE_COMPLETE");quit(0)
