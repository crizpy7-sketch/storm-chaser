extends SceneTree
var game
var checks:=0
var failures:=0

# Media-pack presence checks are skipped (not passed) in trimmed copies; film
# orchestration still runs against a tiny placeholder film from tools/test_media.
const MediaPack = preload("res://scripts/media.gd")
var skipped := 0
func media_check(value: bool, label: String) -> void:
	if MediaPack.media_complete():
		check(value, label)
	else:
		skipped += 1
		print("SKIP: ", label, " (media pack not installed)")

func _initialize() -> void: call_deferred("run")

func check(value: bool, label: String) -> void:
	checks+=1
	if not value: failures+=1
	print("PASS: " if value else "FAIL: ",label)

func fresh() -> void:
	game.start_chase()
	game.set_process(false)
	game.world.set_process(false)
	game.world.mateo.set_process(false)
	game.checkpoints.set_process(false)
	game.auto_dodges=false
	game.speed=240.0;game.wind=0.0

func run() -> void:
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"
	game=load("res://main.tscn").instantiate()
	game.settings_path="user://polish-v09-isolated.cfg"
	root.add_child(game)
	await process_frame
	fresh()
	check(game.world.truck.finish.get_shader_parameter("truck_art")==preload("res://assets/art/truck.png"),"truck uses the original detailed orange artwork")
	var original_vertices = game.world.truck.artwork.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].duplicate()
	game.steer=1.0
	for i in range(60): game._update_driving(1.0/60); game.world.truck.step(1.0/60)
	check(game.world.truck.artwork.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==original_vertices,"steering preserves the original truck mesh without warping")
	check(game.world.truck.wheels.size()==4 and game.world.truck.artwork.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON,"visible 3D body and four wheels render with real shadows")
	check(absf(game.world.truck.body.rotation.z)<=.0451 and absf(game.world.truck.body.position.y)<0.08,"3D suspension and body lean stay bounded")
	game.health=20;game.world.truck.apply_damage()
	check(is_equal_approx(game.world.truck.finish.get_shader_parameter("damage"),0.8),"low hull reveals wear on the original truck artwork")
	game.health=100;game.world.truck.apply_damage()
	check(is_zero_approx(game.world.truck.finish.get_shader_parameter("damage")),"hull repair also repairs visible damage")
	fresh()
	game._spawn_puddle(0)
	game._hit_puddle(game.puddles.back())
	for i in range(30): game._update_driving(1.0/60)
	var standard: float=game.glide_velocity
	fresh()
	game.steering_assist=true
	game._spawn_puddle(0);game.puddles.back().kick=1.0
	game._hit_puddle(game.puddles.back())
	for i in range(30): game._update_driving(1.0/60)
	check(absf(game.glide_velocity)<absf(standard)*0.6,"optional recovery reduces lingering water slide")
	game.steering_assist=false
	var rate: float=game.debris_rate()
	game.relaxed_hazards=true
	check(is_equal_approx(game.debris_rate(),rate*0.78),"reaction assist provides slower hazard arrival")
	game.mode=game.Mode.PAUSED
	game.toggle_option("relaxed_hazards")
	game.toggle_option("steering_assist")
	game.toggle_option("steering_assist")
	check(game.run_assisted,"assisted score label remains after assists are switched off")
	fresh()
	game.elapsed=11.5;game.spawn_timer=0;game.sky_timer=0;game.puddle_timer=0;game.lens_timer=0
	game._simulate(0.01)
	check(game.is_breathing() and game.debris.is_empty() and game.sky_debris.is_empty() and game.puddles.is_empty(),"calm stretch holds new debris and water waves")
	game.elapsed=15;game._simulate(0.01)
	check(not game.is_breathing() and not game.debris.is_empty(),"action resumes after the short calm stretch")
	fresh()
	for i in range(200):game.world.water_fx.splash(1);game.world.water_fx.step(0.025)
	check(game.world.water_fx.pool.size()==32,"water plumes reuse a bounded pool")
	game.world.water_fx.reset()
	check(game.world.water_fx.pool.all(func(p):return not p.node.visible),"reset clears all water plumes")
	game.light_graphics=true;game.world._apply_quality()
	check(not game.world.sun.shadow_enabled and root.msaa_3d==Viewport.MSAA_DISABLED,"lighter graphics removes expensive shadow and MSAA passes")
	game.light_graphics=false;game.world._apply_quality()
	check(game.world.sun.shadow_enabled,"standard graphics restores truck lighting shadows")
	media_check(game.dodges.streams.has(6) and game.dodges.streams.has(7),"both checkpoint movies are available to the footage gallery")
	game.footage_unlocked.clear();game.return_to_menu();game.dodges.show_gallery()
	check(not game.dodges.start_clip(6,true),"unearned checkpoint footage cannot play")
	game.dodges.close_gallery()
	fresh();game.stage=1;game.elapsed=game.STAGE_LENGTH;game.mode=game.Mode.UPGRADE
	game.choose_upgrade(1);game.checkpoints.complete()
	check(game.footage_unlocked==[1],"reaching checkpoint one unlocks only its movie")
	game.pause_chase();game.dodges.show_gallery()
	var before: Dictionary=game.checkpoint.duplicate(true)
	var data: float=game.score
	check(game.dodges.start_clip(6,true),"earned checkpoint footage replays from pause")
	game._simulate(3);game.dodges.finish_clip();game.dodges.close_gallery()
	check(game.mode==game.Mode.PAUSED and game.score==data and game.checkpoint==before,"gallery playback preserves mission, score, checkpoint and pause")
	game.save_enabled=true
	game.steering_assist=true;game.relaxed_hazards=true;game.light_graphics=true;game.mateo_voice=false
	game.save_settings()
	game.steering_assist=false;game.relaxed_hazards=false;game.light_graphics=false;game.mateo_voice=true;game.footage_unlocked.clear()
	game._load_settings()
	check(game.steering_assist and game.relaxed_hazards and game.light_graphics and not game.mateo_voice,"all four new settings survive a save/load")
	check(game.footage_unlocked==[1],"earned footage survives a save/load")
	game.save_enabled=false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.settings_path))
	fresh();game.mateo_voice=true
	var spoke: bool=game.say_mateo("mateo_dodge","I got that!")
	check(spoke and game.mateo_caption=="I got that!","Mateo reaction shows its caption")
	media_check(spoke and game.mateo_audio.stream!=null,"Mateo voice line and caption load together")
	check(not game.say_mateo("mateo_cow","A flying cow?!"),"Mateo reactions respect their cooldown")
	game.pause_chase();game.hud.open_settings()
	var escape:=InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.pressed=true
	game._unhandled_input(escape)
	check(not game.hud.settings_open and game.mode==game.Mode.PAUSED,"Escape closes settings without resuming the chase")
	game.demo=true;game.rng.seed=99152;game.steering_assist=true;game.relaxed_hazards=true
	fresh()
	for i in range(48000):
		if game.mode==game.Mode.UPGRADE: game.choose_upgrade(0);game.checkpoints.complete()
		if game.mode==game.Mode.RUNNING:
			if game.charge>=100: game.deploy_probe()
			game._simulate(1.0/60)
		if game.mode==game.Mode.VORTEX: game.finale.step(1.0/60.0)
		if game.mode in [game.Mode.RESULTS,game.Mode.CRASH]:break
	check(game.result_title=="INTO THE VORTEX" and game.footage_unlocked.has(2),"assisted chase reaches every checkpoint reward and the ending")
	check(game.high_scores.any(func(row):return row.get("assisted",false)),"scoreboard records an assisted completion")
	print("POLISH_TESTS ",checks," checks; ",failures," failures; ",skipped," skipped")
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)
