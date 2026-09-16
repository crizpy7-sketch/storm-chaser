extends SceneTree
var game
var clock:=0.0
var segment:=-1
var marked: Dictionary={}
var impacts: Array[Dictionary]=[]
var last_hits:=0
var second_spawned:=false
func _initialize() -> void:call_deferred("start")
func start() -> void:
	game=load("res://main.tscn").instantiate();game.settings_path="user://solid-impact-movie.cfg";root.add_child(game)
	game.save_enabled=false;game.auto_dodges=false;game.light_graphics=false;game.calm_fx=false
	game.muted=false;AudioServer.set_bus_mute(0,false);game.rng.seed=76314;game.start_chase()
func select(level: int) -> void:
	game.stage=level;game.stage_seen=level;game.elapsed=level*30.0+.2;game.mode=game.Mode.RUNNING
	game.route.enter(level);game.speed=game.CRUISE_SPEEDS[level];game.powertrain.reset(game.speed)
	game.player_x=0;game.velocity_x=0;game._reset_water();game._clear_touch()
	game.debris.clear();game.puddles.clear();game.sky_debris.clear();game.contacts.reset();game.crashes.reset()
	game.health=100;game.boost=100;game.spawn_timer=999;game.sky_timer=999;game.lens_timer=999;game.puddle_timer=999
	game.world.reset_motion();game.hud.rebuild();last_hits=game.hits
	if level==0:
		game.demo=false;game.touch_boost=true
		game._spawn_item(0,.12,.05);game.debris.back().spin=.6;game.debris.back().drift=0
		game.notify("BRACE FOR IMPACT",2)
	else:
		game.demo=true;game.spawn_timer=1.8;game.sky_timer=.45;game.sky_sequence=0
		game.notify("KEEP CLEAR OF FALLING DEBRIS",2)
func _process(dt: float) -> bool:
	if not is_instance_valid(game):return false
	clock+=dt
	var next:=0 if clock<6.0 else 1 if clock<12.5 else 2
	if segment!=next:segment=next;select([0,3,5][segment])
	if game.hits>last_hits:
		impacts.append({"video_second":clock,"stage":game.stage,"hull":game.health,"mph":game.speed})
		last_hits=game.hits
		if not marked.has("Solid-Hit"):shot("Solid-Hit")
	if segment==0 and clock>3.1 and not second_spawned:
		second_spawned=true;game.touch_boost=false
		game._spawn_item(3,clampf(game.player_x+.1,-.65,.65),.08)
		game.debris.back().spin=.3;game.debris.back().drift=0
	if clock>1.0:shot("Civilian-Shelter")
	if clock>2.0:shot("Heavy-Recovery")
	if clock>8.8:shot("Semi-Roof")
	if clock>15.5:shot("Hillside-Shelters")
	if clock>19.0:
		var f:=FileAccess.open(OS.get_environment("STORM_CAPTURE_DIR")+"/solid-impact-capture.json",FileAccess.WRITE)
		f.store_string(JSON.stringify({"seconds":clock,"source":"Actual Godot gameplay; selected stages, scripted impact setups and automated driving","ai_generated_video":false,"stages":[0,3,5],"impacts":impacts,"shelters":4,"civilians":12},"  "))
		print("SOLID_IMPACT_MOVIE_COMPLETE ",impacts.size()," real impacts")
		quit(0)
	return false
func shot(label: String) -> void:
	if marked.has(label):return
	marked[label]=true;call_deferred("save_frame",label)
func save_frame(label: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("STORM_CAPTURE_DIR")+"/"+label+".png")
