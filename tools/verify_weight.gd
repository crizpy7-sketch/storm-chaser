extends SceneTree
var checks := 0
var failures := 0
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
	checks += 1
	if not value: failures += 1
	print("PASS: " if value else "FAIL: ",label)
func accelerate(h: float) -> Dictionary:
	var p = load("res://scripts/powertrain.gd").new()
	p.reset(112.0)
	var speed := 112.0
	for i in range(int(3.0/h)): speed=p.step(h,speed,240,true,false,true,0,0)
	return {"speed":speed,"rpm":p.rpm,"shifts":p.shifts}
func run() -> void:
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"
	var p = load("res://scripts/powertrain.gd").new()
	p.reset(112)
	var speed: float=p.step(0.05,112,240,true,false,true,0,0)
	check(speed < 112.5,"motor builds torque instead of jumping immediately")
	var a=accelerate(1.0/30); var b=accelerate(1.0/60); var c=accelerate(1.0/120)
	print("ACCELERATION_METRICS ",a," ",b," ",c)
	check(absf(a.speed-c.speed)<0.05 and absf(b.speed-c.speed)<0.05,"30/60/120 Hz powertrain agrees")
	check(a.speed>180 and a.speed<235 and a.shifts>=2,"boost builds substantial speed through gear shifts")
	p.reset(150)
	for i in range(60): speed=p.step(1.0/60,150,240,true,false,false,1,0)
	check(speed<150 and p.rpm>5000 and p.load<0.2,"airborne throttle revs without accelerating the truck")
	p.reset(150);speed=150
	for i in range(60): speed=p.step(1.0/60,speed,68,false,true,true,1,0)
	check(speed<90,"braking remains useful before sharp corners")
	var game=load("res://main.tscn").instantiate()
	game.settings_path="user://weight-test-isolated.cfg"
	root.add_child(game);await process_frame
	game.save_enabled=false;game.demo=false;game.start_chase()
	game.set_process(false);game.world.set_process(false)
	game.stage=5;game.route.enter(5);game.world.reset_motion()
	game.velocity_x=0;game.glide_velocity=0;game.route.drift=0
	game.route._land(18)
	check(absf(game.glide_velocity)<0.01,"straight landing does not invent a random sideways kick")
	game.velocity_x=1.1;game.route._land(18)
	check(game.glide_velocity>1.0 and game.aquaplane>0.65,"crooked hard landing preserves momentum and breaks grip")
	var min_y:=0.0
	for i in range(20):
		game.world.truck.step(1.0/120);min_y=minf(min_y,game.world.truck.suspension)
	check(min_y < -0.13 and min_y >= -0.26,"heavy impact visibly compresses suspension within travel stops")
	for i in range(240): game.world.truck.step(1.0/120)
	check(absf(game.world.truck.suspension)<0.03,"suspension settles rather than bouncing indefinitely")
	check(absf(game.world.truck.body.rotation.z)<=.0451 and game.world.truck.body.scale==Vector3.ONE,"weight uses bounded rigid body lean without stretching the truck")
	game.braking=true;game.steer=-1;game.wind=0
	for i in range(120): game._update_driving(1.0/60)
	check(absf(game.glide_velocity)<0.05 and game.aquaplane<0.05,"brake and countersteer recover landing slide")
	game.start_chase()
	check(game.powertrain.acceleration==0 and game.powertrain.shift_time==0,"restart clears engine and transmission transients")
	check(game.motor_body.stream!=null and game.landing_audio.stream!=null,"motor and landing body audio players are ready")
	media_check(game.motor_body.stream.get_length()==4.0,"motor and landing body audio assets load")
	print("WEIGHT_TESTS ",checks," checks; ",failures," failures; ",skipped," skipped")
	game.queue_free();await process_frame;quit(1 if failures else 0)
