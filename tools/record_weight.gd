extends SceneTree
# Actual engine-rendered handling showcase, with isolated stage selection.
var game
var clock := 0.0
var segment := -1
var shots := {}
var max_compression := 0.0
var landings := 0
var last_landings := 0
func _initialize() -> void: call_deferred("start")
func start() -> void:
	game=load("res://main.tscn").instantiate()
	game.settings_path="user://weight-capture-isolated.cfg"
	root.add_child(game)
	game.save_enabled=false;game.demo=true;game.auto_dodges=false
	game.muted=false;AudioServer.set_bus_mute(0,false)
	game.rng.seed=72611;game.start_chase()
func select(level: int) -> void:
	game.stage=level;game.stage_seen=level;game.elapsed=level * game.STAGE_LENGTH
	game.mode=game.Mode.RUNNING;game.route.enter(level)
	game.speed=game.CRUISE_SPEEDS[level];game.powertrain.reset(game.speed)
	game.player_x=0;game.velocity_x=0;game._reset_water()
	game.debris.clear();game.puddles.clear();game.sky_debris.clear()
	game.spawn_timer=3.0;game.health=100;game.boost=100
	game.world.reset_motion();last_landings=0
	game.hud.rebuild()
func _process(dt: float) -> bool:
	if not is_instance_valid(game): return false
	clock+=dt
	var next:=0 if clock<4 else 1 if clock<14 else 2 if clock<24 else 3
	if segment!=next:
		segment=next;select([0,4,5,6][segment])
	if segment==0:
		Input.action_press("boost")
	else: Input.action_release("boost")
	if game.route.landings>last_landings:
		landings+=game.route.landings-last_landings;last_landings=game.route.landings
	max_compression=minf(max_compression,game.world.truck.suspension)
	if clock>11 and segment==1: shot("Mud")
	if game.route.air_height>.6 and segment==2: shot("Hill")
	if game.world.truck.suspension<-.15: shot("Landing")
	if clock>29: shot("Wild-Hills")
	if clock>34:
		var f=FileAccess.open(OS.get_environment("STORM_CAPTURE_DIR")+"/weight-capture.json",FileAccess.WRITE)
		f.store_string(JSON.stringify({"engine_rendered":true,"stage_selection":"showcase, not campaign completion","landings":landings,"max_compression":max_compression,"seconds":clock},"  "))
		print("WEIGHT_CAPTURE_COMPLETE landings=",landings," compression=",max_compression)
		quit(0)
	return false
func shot(label: String) -> void:
	if shots.has(label): return
	shots[label]=true;call_deferred("save_frame",label)
func save_frame(label: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("STORM_CAPTURE_DIR")+"/Weight-"+label+".png")
