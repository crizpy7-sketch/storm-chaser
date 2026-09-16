extends SceneTree
var game
var clock:=0.0
var segment:=-1
var shots: Dictionary={}
var minimum_speed:=999.0
var ruptures:=0
func _initialize() -> void:call_deferred("start")
func start() -> void:
	game=load("res://main.tscn").instantiate();game.settings_path="user://landscape-movie.cfg"
	root.add_child(game);game.save_enabled=false;game.auto_dodges=false;game.demo=true
	game.light_graphics=false;game.calm_fx=false;game.muted=false
	AudioServer.set_bus_mute(0,false);game.rng.seed=75271;game.start_chase()
func select(level: int) -> void:
	game.stage=level;game.stage_seen=level;game.elapsed=level*30.0+1.0
	game.mode=game.Mode.RUNNING;game.route.enter(level)
	game.speed=game.CRUISE_SPEEDS[level];game.powertrain.reset(game.speed)
	game.player_x=0;game.velocity_x=0;game._reset_water()
	game.debris.clear();game.puddles.clear();game.sky_debris.clear()
	game.spawn_timer=2;game.sky_timer=1.4;game.lens_timer=7.5
	game.sky_sequence=0;game.health=100;game.boost=100
	game.world.reset_motion();game.hud.rebuild()
func _process(dt: float) -> bool:
	if not is_instance_valid(game):return false
	clock+=dt
	var next:=0 if clock<6 else 1 if clock<11 else 2
	if segment!=next:segment=next;select([1,3,5][segment])
	minimum_speed=minf(minimum_speed,game.speed)
	if clock>3.3:shot("Wreck-Flyby")
	if clock>4.2:shot("Roadside-Fire")
	if clock>9.5:shot("Crosswind-Damage")
	if clock>15:shot("Hillside-Ruins")
	if clock>17:
		var f=FileAccess.open(OS.get_environment("STORM_CAPTURE_DIR")+"/landscape-capture.json",FileAccess.WRITE)
		f.store_string(JSON.stringify({"seconds":clock,"source":"Actual Godot gameplay; selected stages and automated driving","stages":[1,3,5],"ai_generated_video":false,"landscape_clusters":game.world.landscape.clusters.size(),"semi_sections":16,"minimum_speed_mph":minimum_speed},"  "))
		print("LANDSCAPE_MOVIE_COMPLETE")
		quit(0)
	return false
func shot(label: String) -> void:
	if shots.has(label):return
	shots[label]=true;call_deferred("save_frame",label)
func save_frame(label: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("STORM_CAPTURE_DIR")+"/Storm-"+label+".png")
