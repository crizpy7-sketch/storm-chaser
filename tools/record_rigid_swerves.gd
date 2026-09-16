extends SceneTree
var game
var clock:=0.0
var segment:=-1
var poses: Dictionary={}
var shots: Dictionary={}
func _initialize() -> void:call_deferred("start")
func start() -> void:
	game=load("res://main.tscn").instantiate()
	game.settings_path="user://storm-upgrade-capture.cfg"
	root.add_child(game)
	game.save_enabled=false;game.auto_dodges=false;game.demo=true
	game.muted=false;AudioServer.set_bus_mute(0,false)
	game.rng.seed=72611;game.start_chase()
func select(level: int) -> void:
	game.stage=level;game.stage_seen=level;game.elapsed=level * game.STAGE_LENGTH
	game.mode=game.Mode.RUNNING;game.route.enter(level)
	game.speed=game.CRUISE_SPEEDS[level];game.powertrain.reset(game.speed)
	game.player_x=0;game.velocity_x=0;game._reset_water()
	game.debris.clear();game.puddles.clear();game.sky_debris.clear()
	game.spawn_timer=3;game.health=100;game.boost=100
	game.world.reset_motion();game.hud.rebuild()
func _process(dt: float) -> bool:
	if not is_instance_valid(game):return false
	clock+=dt
	var next:=0 if clock<8 else 1 if clock<12 else 2
	if next!=segment:
		segment=next;select([3,5,7][segment])
	game.demo=segment!=0
	Input.action_release("left");Input.action_release("right")
	if segment==0:
		var axis:=sin(clock*1.6)*1.0
		Input.action_press("right" if axis>0 else "left",absf(axis))
	var pose: String=game.world.truck.current_pose
	poses[pose]=int(poses.get(pose,0))+1
	if clock>1.0:shot("Rigid-1")
	if clock>3.0:shot("Rigid-3")
	if clock>5.0:shot("Rigid-5")
	if clock>9.0:shot("Rigid-Air")
	if clock>13:shot("Rigid-Tornado")
	if clock>15:
		var f=FileAccess.open(OS.get_environment("STORM_CAPTURE_DIR")+"/rigid-swerve-capture.json",FileAccess.WRITE)
		f.store_string(JSON.stringify({"seconds":clock,"poses":poses,"suction_objects":game.world.destruction.pieces.size(),"stage_selection":"showcase; actual game logic, scripted steering and automated driver"},"  "))
		print("RIGID_SWERVE_CAPTURE_COMPLETE ",poses)
		quit(0)
	return false
func shot(label: String) -> void:
	if shots.has(label):return
	shots[label]=true;call_deferred("save_frame",label)
func save_frame(label: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("STORM_CAPTURE_DIR")+"/Storm-"+label+".png")
