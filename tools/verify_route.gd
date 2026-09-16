extends SceneTree
var game
var checks:=0
var failures:=0
const MediaPack = preload("res://scripts/media.gd")
func _initialize() -> void:call_deferred("run")
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1
	print("PASS: " if value else "FAIL: ",label)
func enter(level: int) -> void:
	game.start_chase()
	game.set_process(false);game.world.set_process(false);game.checkpoints.set_process(false)
	game.world.mateo.set_process(false)
	game.stage=level;game.stage_seen=level;game.elapsed=level*30.0
	game.route.enter(level);game.speed=game.CRUISE_SPEEDS[level]
	game.wind=0;game.steer=0

func drive_shortcut(speed: float, recover: bool) -> Dictionary:
	enter(4);game.route.progress=100.0;game.speed=speed;game.braking=speed<80
	var result: Dictionary={"slide":0.0,"yaw":0.0,"yaw_step":0.0,"drift":0.0,"lane":0.0}
	for i in range(720):
		if game.route.progress>=280.0: break
		game.steer=clampf(-game.player_x*6.5-game.route.drift*0.85,-1.0,1.0) if recover else 0.0
		var before: float=game.truck_yaw
		game.route.step(1.0/60.0);game._update_driving(1.0/60.0)
		result.slide=maxf(result.slide,game.route.shortcut_slide)
		result.yaw=maxf(result.yaw,absf(game.truck_yaw))
		result.yaw_step=maxf(result.yaw_step,absf(game.truck_yaw-before))
		result.drift=maxf(result.drift,absf(game.route.drift))
		result.lane=maxf(result.lane,absf(game.player_x))
	result.exit_drift=absf(game.route.drift);result.exit_slide=game.route.shortcut_slide
	return result

func run() -> void:
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"
	game=load("res://main.tscn").instantiate()
	game.settings_path="user://route-v010-isolated.cfg"
	root.add_child(game)
	await process_frame
	# The route suite exercises the in-engine fallback; verify_finale covers the film.
	game.finale.movies_enabled = false
	for level in range(3,8):
		enter(level)
		game.route.progress=180.0
		check(game.route.point(0).length()<0.0001,"level %d course remains at truck origin" % (level+1))
		var before: Vector2=game.route.course(180)
		var after: Vector2=game.route.course(180.1)
		check(before.distance_to(after)<0.102,"level %d course is continuous" % (level+1))
	enter(4)
	check(absf(game.route.heading(245)-PI*.5)<0.001,"shortcut turns a full ninety degrees right")
	check(game.route.width(-350)<11.01 and game.route.width(0)>13.99,"separate mud road is narrower than the highway")
	var junction: float=game.route.SHORTCUT_JUNCTION_Z
	check(game.route.course(130).x==0.0 and absf(game.route.course(210).y+junction)<.0001,"highway and mud road have perpendicular straight centerlines")
	check(game.route.dirt_at(140)==0 and game.route.dirt_at(156)==1,"asphalt stays asphalt until crossing its right edge")
	var on_road:=true
	for i in range(120,220):
		var p: Vector2=game.route.course(float(i))
		on_road=on_road and (absf(p.x)<=7.001 or (p.x>=7.0 and absf(p.y+junction)<=5.501))
	check(on_road,"tight driving line stays inside the square junction")
	check(game.route.SHORTCUT_TURN_END-game.route.SHORTCUT_TURN_START<23.0,"right turn completes at the junction, without a sweeping exit ramp")
	check(game.route.course(260.001).distance_to(game.route.course(259.999))<.0021,"perpendicular dirt road joins the later hills continuously")
	var original_mesh=game.world.truck.artwork.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var fast_corner:=drive_shortcut(122.0,true)
	var slow_corner:=drive_shortcut(68.0,true)
	var unattended_corner:=drive_shortcut(122.0,false)
	check(fast_corner.slide>0.8 and fast_corner.drift>1.0,"shortcut creates sustained rear drift at cruise speed")
	check(slow_corner.slide<fast_corner.slide*.25 and slow_corner.drift<fast_corner.drift,"braking reduces shortcut slide and outward force")
	check(unattended_corner.lane>1.0 and fast_corner.lane<0.85,"steering controls the actual lateral slide through the right turn")
	check(fast_corner.yaw>.10 and fast_corner.yaw<=.13001 and fast_corner.yaw_step<.025,"dramatic corner keeps original bounded smooth truck heading")
	check(fast_corner.exit_slide<.01 and fast_corner.exit_drift<.25,"corner slide settles after the exit")
	check(game.world.truck.artwork.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==original_mesh,"drift leaves all original truck vertices unchanged")
	enter(4)
	check(game.route.shortcut_slide==0 and not game.route.shortcut_entry_played and not game.route.shortcut_mud_played and game.route.drift==0,"checkpoint entry clears corner momentum and both effect latches")
	game.route.progress=162;game.route.dirt=1;game.world._update_view(0)
	var rendered_road=game.world.road.mesh.surface_get_arrays(0)
	var junction_vertices: PackedVector3Array=rendered_road[Mesh.ARRAY_VERTEX]
	var highway_axis: Vector3=(junction_vertices[2]-junction_vertices[0]).normalized()
	var dirt_axis: Vector3=(junction_vertices[8]-junction_vertices[6]).normalized()
	check(absf(highway_axis.dot(dirt_axis))<.00001,"visible highway and mud road meshes meet at exactly ninety degrees")
	var surface_colors: PackedColorArray=rendered_road[Mesh.ARRAY_COLOR]
	var hard_seam:=true
	for i in range(12): hard_seam=hard_seam and surface_colors[i].r==(0.0 if i<6 else 1.0)
	check(hard_seam,"junction meshes have a hard asphalt-to-mud seam with no blending ramp")
	var field_vertices: PackedVector3Array=game.world.terrain.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var overturned:=0
	for i in range(0,field_vertices.size(),3):
		if (field_vertices[i+1]-field_vertices[i]).cross(field_vertices[i+2]-field_vertices[i]).y < -0.0001: overturned+=1
	check(overturned==0,"hairpin terrain has no folded or overturned triangles")
	print("SHORTCUT_METRICS fast=",fast_corner," slow=",slow_corner," unattended=",unattended_corner)
	var water=game.world.water_fx
	water.reset();game.route.dirt=0;water.splash(.9)
	check(water.mud_hits==0,"asphalt puddles keep clean water instead of mud on screen")
	game.route.dirt=1;game.route.grounded=true;water.splash(.9);water.step(.35)
	check(water.mud_hits==1 and water.mud_lens.visible and water.mud_age>.3,"mud puddle launches a visible lens splash")
	water.step(3.65)
	water.splash(.9)
	check(water.mud_hits==1 and water.mud_age>=4.0,"repeated puddles cannot repaint the lens before its mud drains")
	game.pause_chase();var mud_before: float=water.mud_age;water.step(1.0)
	check(water.mud_age==mud_before and not water.mud_lens.visible,"pause freezes and hides mud overlay")
	game.resume_chase();water.step(5.7)
	check(not water.mud_lens.visible,"mud drains off the lens without permanently blocking play")
	water.reset();game.route.grounded=false;water.mud_screen_splash(1.0)
	check(water.mud_hits==0,"airborne truck cannot kick ground mud onto the lens")
	game.route.grounded=true;water.mud_screen_splash(1.0);water.reset()
	check(water.mud_hits==0 and not water.mud_lens.visible,"retry clears all lens mud")
	for level in [5,6]:
		enter(level)
		var peak:=0.0
		for i in range(900):
			game.route.step(1.0/60.0)
			peak=maxf(peak,game.route.air_height)
		check(game.route.launches>0 and game.route.landings>0 and peak>0.5,"big hills launch and land at level %d cruise" % (level+1))
		print("JUMP level=",level," height=",peak," launches=",game.route.launches," landings=",game.route.landings)
		enter(level);game.speed=68;game.braking=true
		for i in range(1800):game.route.step(1.0/60.0)
		check(game.route.launches==0,"braking keeps level %d hills grounded" % (level+1))
	enter(3);game.route.progress=185;game.speed=146
	for i in range(30):game.route.step(1.0/60)
	var fast: float=absf(game.route.drift)
	enter(3);game.route.progress=185;game.speed=68;game.braking=true
	for i in range(30):game.route.step(1.0/60)
	check(absf(game.route.drift)<fast*0.6,"lower speed and brake reduce bend drift")
	enter(5);game.route.progress=123;game.route.body_y=game.route.height_at(123)
	game._spawn_item(0,0.4);game.debris[0].z=0.8
	game.world._update_view(0)
	var expected: Vector3=game.world.road_point(-17.0,0.4)
	check(absf(game.world.hazard_nodes[0].position.x-expected.x)<0.0001 and game.world.hazard_nodes[0].position.y>expected.y,"debris rides the curved elevated surface")
	game.debris.clear();game._spawn_item(0,0);game.debris[0].z=.999
	game.route.air_height=4.0;game.health=100;game._update_debris(.02)
	check(game.health==100 and game.hits==0,"high jump clears low road debris")
	# Independent grounded case: don't teleport down onto the previous test's object.
	game.debris.clear();game._spawn_item(0,0);game.debris.back().z=.999;game.route.air_height=0
	game._update_debris(.02)
	check(game.health<100 and game.hits==1,"grounded truck still takes debris damage")
	enter(5);game.route.grounded=false
	game._spawn_puddle(0);game._hit_puddle(game.puddles.back())
	check(game.puddle_hits==0,"airborne truck cannot aquaplane on a puddle below it")
	game.world.water_fx.reset()
	var emitted: int=game.world.water_fx.cursor
	game.world.water_fx.step(.1)
	check(game.world.water_fx.cursor==emitted,"airborne tires stop emitting ground mist")
	for level in range(3,8):
		enter(level);game.mode=game.Mode.UPGRADE;game.choose_upgrade(1)
		check(game.checkpoints.route_preview and game.checkpoints.film_playing == (level in [3,4,5,6,7]),"level %d uses its available movie or in-engine preview" % (level+1))
		if level in [3,4,5,6,7]: game.checkpoints.player.finished.emit()
		else: game.checkpoints.step(2.9)
		check(game.can_retry_checkpoint() and game.checkpoint.stage==level,"new level %d checkpoint saves" % (level+1))
		var saved: float=game.score
		game.score+=1000;game.route.progress=400;game.route.air_height=4;game.retry_checkpoint()
		check(game.score==saved and game.route.progress==0 and game.route.grounded and game.route.air_height==0,"retry %d resets terrain motion without extra rewards" % (level+1))
	enter(7);game.route.progress=game.route.ORBIT_APPROACH+game.route.ORBIT_RADIUS*TAU*0.5
	check(absf(game.route.orbit_progress()-0.5)<.0001,"tornado lap tracks actual course distance")
	var saved_progress: float=game.route.progress
	game.pause_chase();game._simulate(3)
	check(game.route.progress==saved_progress,"pause freezes road and airborne simulation")
	game.resume_chase();game.probes=3;game.route.progress=game.route.ORBIT_APPROACH+game.route.ORBIT_RADIUS*TAU
	game._simulate(.001)
	check(game.mode==game.Mode.VORTEX and game.finale.active,"completing circle triggers suction finale")
	game.finale.step(3.5);game.pause_chase()
	var age: float=game.finale.age
	game.finale.step(4)
	check(game.finale.age==age,"pause freezes suction finale")
	game.resume_chase()
	check(game.mode==game.Mode.VORTEX,"resume returns to finale without restarting gameplay")
	game.finale.step(9)
	var score: float=game.score
	game.finale.complete()
	check(game.mode==game.Mode.RESULTS and game.result_title=="INTO THE VORTEX" and game.score==score,"finale ends once with results and no duplicate reward")
	check(game.world.mateo.get_parent()==game.world.truck.body,"Mateo stays attached through hills and vortex")
	check(game.finale.finished,"results retain the airborne final camera")
	enter(5);game.velocity_x=1.5;game.glide_velocity=.4
	game.route._land(19.0)
	check(game.health<100 and game.route.hard_landings==1 and game.glide_velocity>.4,"sideways hard landing damages hull and creates recovery slide")
	enter(7);game.save_checkpoint();game.probes=0;game.finale.begin();game.finale.step(12)
	check(game.result_title=="SURVEY INCOMPLETE" and game.can_retry_checkpoint(),"fewer than three probes preserves survey objective and checkpoint retry")
	var legacy: Dictionary=game.checkpoint.duplicate(true)
	legacy.version=1;legacy.stage=2
	check(game.valid_checkpoint(legacy),"older two-building checkpoint remains compatible")
	legacy.stage=7
	check(not game.valid_checkpoint(legacy),"old save schema cannot pretend to contain a new level")
	print("ROUTE_TESTS ",checks," checks; ",failures," failures")
	game.queue_free();await process_frame;quit(0 if failures==0 else 1)
