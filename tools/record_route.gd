extends SceneTree
# Edited gameplay highlights: omitted portions are simulated with the same
# driving rules; health, earned upgrades and score carry through every chapter.
var game
var wall:=0.0
var clip_age:=0.0
var clip_stage:=-1
var ending_age:=0.0
var final_approach_cut:=false
var shots: Dictionary={}
const SHOWN:={3:6.0,4:17.0,5:7.0,6:8.0}
func _initialize() -> void:call_deferred("start")
func start() -> void:
	game=load("res://main.tscn").instantiate();game.settings_path="user://route-capture-isolated.cfg"
	root.add_child(game)
	game.demo=true;game.auto_dodges=false;game.save_enabled=false;game.rng.seed=72611
	game.start_chase()
	fast_forward(3)
	game.choose_upgrade(0 if game.health<80 else 1)
	game.checkpoints.complete()
	game.world._update_view(0)
	print("PREVIEW_START stage=",game.stage," health=",game.health," score=",game.score)
func fast_forward(target_stage: int) -> void:
	for i in range(7000):
		if game.stage>=target_stage and game.mode==game.Mode.UPGRADE:return
		if game.mode==game.Mode.UPGRADE:
			game.choose_upgrade(0 if game.health<80 else 1);game.checkpoints.complete()
		if game.mode!=game.Mode.RUNNING:
			printerr("Preview run unexpectedly stopped at ",game.mode);quit(1);return
		if game.charge>=100:game.deploy_probe()
		game._simulate(1.0/60)
	printerr("Preview fast-forward exhausted");quit(1)
func _process(dt: float) -> bool:
	if not is_instance_valid(game):return false
	wall+=dt
	if game.stage!=clip_stage:
		clip_stage=game.stage;clip_age=0
		print("LEVEL ",clip_stage+1," wall=",wall," hull=",game.health," data=",game.score)
	if game.mode==game.Mode.RUNNING:
		if game.stage==7 and not final_approach_cut:
			final_approach_cut=true
			for i in range(2200):
				if game.route.orbit_progress()>=0.72:break
				if game.charge>=100:game.deploy_probe()
				game._simulate(1.0/60)
			game.world.reset_motion();game.world._update_view(0)
			print("FINAL_LAP_HIGHLIGHT progress=",game.route.orbit_progress())
		clip_age+=dt
		if game.stage==3 and clip_age>5:shot("Curves")
		if game.stage==4 and game.route.progress>165 and game.route.progress<210:shot("Shortcut")
		if game.stage==5 and game.route.air_height>1.8:shot("Airborne")
		if game.stage==6 and game.route.air_height>4:shot("Wild-Hills")
		if game.stage==7 and game.route.orbit_progress()>.22:shot("Circle-the-Tornado")
		if SHOWN.has(game.stage) and clip_age>SHOWN[game.stage]:
			print("CUT level=",game.stage+1," jumps=",game.route.launches," landings=",game.route.landings," hull=",game.health)
			fast_forward(game.stage+1)
	elif game.mode==game.Mode.VORTEX:
		if game.finale.age>7.7:shot("Into-the-Vortex")
	elif game.mode==game.Mode.RESULTS:
		ending_age+=dt
		if ending_age>.2:shot("Results")
		if ending_age>2.5:
			print("ROUTE_CAPTURE_COMPLETE wall=",wall," title=",game.result_title," score=",game.score," health=",game.health)
			quit()
	elif game.mode==game.Mode.CRASH:
		printerr("CAPTURE_FAILED: truck destroyed");quit(1)
	if wall>125:quit(1)
	return false
func shot(label: String) -> void:
	if shots.has(label):return
	shots[label]=wall;call_deferred("save_frame",label)
func save_frame(label: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	var destination: String="../" if "--native-capture" in OS.get_cmdline_user_args() else "../exports/"
	root.get_texture().get_image().save_png(destination+"Storm-Chaser-v0.10.0-"+label+".png")
