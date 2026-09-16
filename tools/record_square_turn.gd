extends SceneTree
# Actual gameplay from the exported game. Prior stages use normal rules.
var game
var wall:=0.0
var shots: Dictionary={}
var peak_slide:=0.0
var peak_yaw:=0.0
func _initialize() -> void: call_deferred("start")
func start() -> void:
	game=load("res://main.tscn").instantiate()
	game.settings_path="user://square-turn-capture-isolated.cfg"
	root.add_child(game)
	game.demo=true;game.auto_dodges=false;game.save_enabled=false;game.rng.seed=72611
	game.start_chase()
	if not is_instance_valid(game.world.get("camera")):
		printerr("JUNCTION_CAPTURE_FAILED world did not initialize");quit(1);return
	for i in range(8500):
		if game.mode==game.Mode.UPGRADE:
			game.choose_upgrade(0 if game.health<80 else 1)
			game.checkpoints.complete()
			if game.stage==4:break
		if game.mode!=game.Mode.RUNNING:
			printerr("JUNCTION_CAPTURE_FAILED approach");quit(1);return
		if game.charge>=100:game.deploy_probe()
		game._simulate(1.0/60.0)
	game.world._update_view(0)
	print("JUNCTION_CAPTURE_START stage=",game.stage," hull=",game.health," data=",game.score)
func _process(dt: float) -> bool:
	if not is_instance_valid(game):return false
	wall+=dt
	peak_slide=maxf(peak_slide,game.route.shortcut_slide)
	peak_yaw=maxf(peak_yaw,absf(game.truck_yaw))
	if game.route.progress>135.0:shot("Square-Junction")
	if game.route.progress>150.0:shot("Hard-Right")
	if game.world.water_fx.mud_hits>0 and game.world.water_fx.mud_age>.48:shot("Mud-On-Screen")
	if game.route.progress>325.0 and game.world.water_fx.mud_age>=5.7:shot("Mud-Cleared")
	if game.mode!=game.Mode.RUNNING:
		printerr("JUNCTION_CAPTURE_FAILED mode=",game.mode);quit(1)
	if wall>18.0:
		print("JUNCTION_CAPTURE_COMPLETE stage=",game.stage," peak_slide=",peak_slide," peak_yaw=",peak_yaw," mud_hits=",game.world.water_fx.mud_hits," cleared=",shots.has("Mud-Cleared")," hull=",game.health," progress=",game.route.progress," wall=",wall)
		quit(0 if peak_slide>.8 and peak_yaw>.1 and peak_yaw<=.13001 and game.world.water_fx.mud_hits>0 and shots.has("Mud-Cleared") and game.health>0 else 1)
	return false
func shot(label: String) -> void:
	if shots.has(label):return
	shots[label]=true;call_deferred("save_frame",label)
func save_frame(label: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	var destination: String="../" if "--native-capture" in OS.get_cmdline_user_args() else "../exports/"
	root.get_texture().get_image().save_png(destination+"Storm-Chaser-v0.10.4-"+label+".png")
