extends SceneTree
var game
var wall:=0.0
var boost_latched:=false
var upgrade_age:=0.0
var ending_age:=0.0
var phase:=0
var shots: Dictionary={}

func _initialize() -> void: call_deferred("start")

func start() -> void:
	game=load("res://main.tscn").instantiate()
	game.settings_path="user://capture-v09.cfg"
	root.add_child(game)
	game.save_enabled=false
	game.auto_dodges=false
	game.footage_unlocked.clear()
	game.rng.seed=72611
	game.start_chase()

func _process(dt: float) -> bool:
	if not is_instance_valid(game): return false
	wall+=dt
	if "--preview-truck" in OS.get_cmdline_user_args() and wall>18.0:
		clear_input()
		print("TRUCK_STYLE_CAPTURE_DONE wall=",wall," puddles=",game.puddle_hits," hull=",game.health)
		quit()
		return false
	if phase==0 and "--preview-short" in OS.get_cmdline_user_args() and wall>43.0 and game.mode==game.Mode.RUNNING:
		clear_input()
		print("PREVIEW_SECTION_END wall=",wall," chase=",game.elapsed," hull=",game.health," data=",int(game.score))
		game.return_to_menu()
		game.dodges.show_gallery()
		phase=1;ending_age=0.0
	if phase==0:
		if game.mode==game.Mode.RUNNING:
			if game.elapsed>2.0:shot("Truck-Style")
			var target: float=game._demo_target()
			# Use ordinary controller inputs to cross the first puddle, then chase safely.
			if game.elapsed<7.0:
				for p in game.puddles:
					if not p.hit and p.z>-85: target=p.lane; break
			var turn: float=clampf((target-game.player_x)*6.5-game.glide_velocity*0.75,-1,1)
			Input.action_press("left",maxf(0,-turn))
			Input.action_press("right",maxf(0,turn))
			if game.boost<=18 or game.distance<670:boost_latched=false
			elif game.boost>70 and game.distance>820:boost_latched=true
			if boost_latched:Input.action_press("boost")
			else:Input.action_release("boost")
			if game.distance<550:Input.action_press("brake")
			else:Input.action_release("brake")
			if game.charge>=100:game.deploy_probe()
			if game.splash_pulse>0.28 and game.splash_pulse<0.62:shot("Puddle")
			if game.elapsed>24 and game.elapsed<27:shot("Checkpoint-Approach")
			if game.health<60:shot("Truck-Damage")
			if game.stage==2:shot("Warehouse-Front")
		elif game.mode==game.Mode.UPGRADE:
			clear_input()
			upgrade_age+=dt
			if upgrade_age>0.7:
				print("UPGRADE_CAPTURE front=",game.stage," wall=",wall," hull=",game.health)
				game.choose_upgrade(0 if game.health<80 else 1)
				upgrade_age=0.0
		elif game.mode==game.Mode.RESULTS:
			clear_input()
			ending_age+=dt
			if ending_age>2.0:
				print("CHASE_CAPTURE_RESULT ",game.result_title," data=",int(game.score)," hull=",game.health," wall=",wall)
				shot("Results")
				game.return_to_menu()
				game.dodges.show_gallery()
				phase=1;ending_age=0
		elif game.mode in [game.Mode.CELEBRATION,game.Mode.CHECKPOINT,game.Mode.CRASH]: clear_input()
	elif phase==1:
		ending_age+=dt
		if ending_age>0.25:shot("Mateos-Footage")
		if ending_age>3.0:
			game.dodges.close_gallery();game.hud.open_settings();phase=2;ending_age=0
	elif phase==2:
		ending_age+=dt
		if ending_age>0.25:shot("Driving-Settings")
		if ending_age>3.0:
			print("UPGRADE_CAPTURE_DONE wall=",wall," puddles=",game.puddle_hits," earned_films=",game.footage_unlocked)
			quit()
	if wall>125: quit(1)
	return false

func clear_input() -> void:
	for action in ["left","right","brake","boost"]:Input.action_release(action)

func shot(label: String) -> void:
	if shots.has(label):return
	shots[label]=wall
	call_deferred("save_frame",label)

func save_frame(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var version: String = ProjectSettings.get_setting("application/config/version", "0.9.1")
	root.get_texture().get_image().save_png("../exports/Storm-Chaser-v"+version+"-"+label+".png")
