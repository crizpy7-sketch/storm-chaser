extends SceneTree
# Pure gameplay: earlier driving is simulated normally, and the existing
# checkpoint film is skipped before this capture begins.
var game
var wall:=0.0
var shots: Dictionary={}
var peak_slide:=0.0
var peak_yaw:=0.0
func _initialize() -> void: call_deferred("start")
func start() -> void:
	game=load("res://main.tscn").instantiate()
	game.settings_path="user://mud-drift-capture-isolated.cfg"
	root.add_child(game)
	game.demo=true;game.auto_dodges=false;game.save_enabled=false;game.rng.seed=72611
	game.start_chase()
	if not is_instance_valid(game.world.get("camera")):
		printerr("MUD_CAPTURE_FAILED world did not initialize");quit(1);return
	for i in range(8500):
		if game.mode==game.Mode.UPGRADE:
			game.choose_upgrade(0 if game.health<80 else 1)
			game.checkpoints.complete()
			if game.stage==4:break
		if game.mode!=game.Mode.RUNNING:
			printerr("MUD_CAPTURE_FAILED approach");quit(1);return
		if game.charge>=100:game.deploy_probe()
		game._simulate(1.0/60.0)
	game.world._update_view(0)
	print("MUD_CAPTURE_START stage=",game.stage," hull=",game.health," data=",game.score)
func _process(dt: float) -> bool:
	if not is_instance_valid(game):return false
	wall+=dt
	peak_slide=maxf(peak_slide,game.route.shortcut_slide)
	peak_yaw=maxf(peak_yaw,absf(game.truck_yaw))
	if game.route.shortcut_slide>.9:shot("Right-Drift")
	if game.route.progress>290.0:shot("Mud-Trail")
	if game.route.progress>385.0:shot("Small-Hills")
	if game.mode!=game.Mode.RUNNING:
		printerr("MUD_CAPTURE_FAILED mode=",game.mode);quit(1)
	if wall>18.0:
		print("MUD_CAPTURE_COMPLETE stage=",game.stage," peak_slide=",peak_slide," peak_yaw=",peak_yaw," hull=",game.health," progress=",game.route.progress," wall=",wall)
		quit(0 if peak_slide>.8 and peak_yaw>.1 and peak_yaw<=.13001 and game.health>0 else 1)
	return false
func shot(label: String) -> void:
	if shots.has(label):return
	shots[label]=true;call_deferred("save_frame",label)
func save_frame(label: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	var destination: String="../" if "--native-capture" in OS.get_cmdline_user_args() else "../exports/"
	root.get_texture().get_image().save_png(destination+"Storm-Chaser-v0.10.3-"+label+".png")
