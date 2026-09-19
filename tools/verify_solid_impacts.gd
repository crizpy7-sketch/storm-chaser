extends SceneTree
var game
var checks:=0
var failures:=0
const MediaPack = preload("res://scripts/media.gd")
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print("PASS: " if ok else "FAIL: ",label)
func fresh() -> void:
	game.start_chase();game.set_process(false);game.world.set_process(false)
	game.speed=180;game.demo=false;game.auto_dodges=false;game.elapsed=0;game.bend=0;game.wind=0
	game.debris.clear();game.world._update_view(0.0)
func item(lane: float,z: float,kind: int = 0) -> Dictionary:
	game._spawn_item(kind,lane,z)
	var d: Dictionary=game.debris.back();d.phase=0;d.angle=0;d.spin=0;d.drift=0;return d
func advance(dt: float) -> void:
	game.elapsed+=dt;game._update_debris(dt);game.world._update_view(0.0)
func bounds(node: Node3D) -> AABB:
	var pts:=PackedVector3Array();game.world._collect_bounds(node,Transform3D.IDENTITY,pts)
	var b:=AABB(pts[0],Vector3.ZERO)
	for p in pts:b=b.expand(p)
	return b
func run() -> void:
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"
	game=load("res://main.tscn").instantiate();game.settings_path="user://solid-contact-qa.cfg"
	root.add_child(game);await process_frame;game.save_enabled=false;fresh()
	check(game.world.hazard_bounds(0,0).size.x>1.4,"collision bounds come from visible hazard geometry")
	var d:=item(0,.90)
	for i in range(40):
		advance(.005)
		if game.hits>0:break
	check(game.hits==1 and d.z<.98,"front bumper takes contact before debris reaches the truck center")
	check(game.health<100 and game.speed<160,"physical strike removes hull and forward speed")
	check(d.has("impact_transform") and game.world.hazard_nodes[0].transform.is_equal_approx(d.impact_transform),"rendered object stops at its swept contact transform")
	check(game.world.contact_fx.last_origin.z< -2.5 and game.crashes.origin.is_equal_approx(game.world.camera.unproject_position(game.world.contact_fx.last_origin)),"impact effects originate at the actual front contact")
	var hit_point: Vector3=d.impact_transform.origin
	advance(.15)
	check(game.world.hazard_transform(d,game.elapsed).origin.z<hit_point.z,"debris deflects away from the front instead of crossing the chassis")
	check(game.hits==1,"the same impact never damages twice")
	var health: float=game.health
	item(0,.95);advance(.03)
	check(game.hits==2 and game.health<health and game.invulnerable>0,"a second solid object still strikes during recovery")
	game.world.truck.step(.05)
	check(game.world.truck.suspension<0 and game.world.truck.recoil.length()>0,"contact compresses suspension and moves the body as a rigid unit")
	check(game.world.truck.body.scale==Vector3.ONE,"impact preserves the approved truck proportions")
	for i in range(120):game.world.truck.step(1.0/60)
	check(game.world.truck.recoil.length()<.001,"rigid recoil settles without permanent offset")
	game.stage=7;game.route.enter(7);game.route.progress=160;game.world._update_view(0)
	check(game.contacts.truck_transform().basis.is_equal_approx(game.world.truck.basis),"vortex camera view and physical truck use the same heading")
	fresh();item(.63,.87)
	for i in range(35):advance(.02)
	check(game.hits==0 and game.health==100,"a visible side clearance causes no phantom damage")
	fresh();item(0,.60);advance(1.0)
	check(game.hits==1,"continuous contact catches a large step that crosses the whole vehicle")
	fresh();game.route.air_height=4.0;item(0,.86)
	for i in range(30):advance(.02)
	check(game.hits==0,"a genuinely high jump clears low debris")
	fresh();game.route.air_height=.55;item(0,.95);advance(.03)
	check(game.hits==1,"airborne truck still collides when its body intersects debris")
	fresh();game.truck_yaw=.70
	var box:=AABB(Vector3(-.15,-.15,-.15),Vector3(.30,.30,.30))
	var pose: Transform3D=game.contacts.truck_transform()*Transform3D(Basis.IDENTITY,Vector3(0,1,-2.88))
	check(not game.contacts.sweep(pose,pose,box).is_empty(),"collision hull rotates with the steered vehicle")
	var old: Transform3D=Transform3D(Basis.IDENTITY,Vector3(0,1,0))
	game.contacts.previous_truck=Transform3D(Basis.IDENTITY,Vector3(-4,0,0));game.contacts.has_previous=true
	game.player_x=.7
	check(not game.contacts.sweep(old,old,box).is_empty(),"truck lateral movement can sweep into a stationary object")
	fresh();game.health=63;item(0,.94,4);advance(.08)
	check(game.health==81 and game.hits==0,"supply uses physical contact but repairs the truck")
	fresh();game._spawn_sky_piece(0,1)
	var piece: Dictionary=game.sky_debris.back();piece.age=piece.duration*.36
	var part: Node3D=game.world.semi_wreck_template.get_node("RoofSheet00")
	var expected: Transform3D=game.world.sky_transform(piece)*preload("res://scripts/semi_wreck.gd").part_transform(part,.36)
	game._shed_semi_roof(piece);var sheet: Dictionary=game.debris.back()
	check(game.world.hazard_transform(sheet,game.elapsed).is_equal_approx(expected),"falling sheet starts at exactly the torn semi roof position and orientation")
	game.world._update_sky()
	check(not game.world.sky_nodes[0].parts[10].visible and piece.shed,"original roof disappears when its physical hazard takes over")
	game._shed_semi_roof(piece)
	check(game.debris.size()==1,"semi sheds only one collidable roof sheet")
	var roof_hit:=false
	for i in range(160):
		advance(.02)
		if game.hits>0:roof_hit=true;break
	check(roof_hit,"torn semi roof follows a real damaging flight through the driving corridor")
	var clear:=true
	for side in [-1.0,1.0]:
		piece.side=side
		for j in range(41):
			var u:=j/40.0;piece.age=u*piece.duration
			var sky: Transform3D=game.world.sky_transform(piece)
			for p in game.world.semi_wreck_template.get_children():
				var shape: AABB=bounds(p)
				var at: Transform3D=sky*preload("res://scripts/semi_wreck.gd").part_transform(p,u)
				for lane in [-1.1,0.0,1.1]:
					game.player_x=lane;game.contacts.reset()
					clear=clear and game.contacts.sweep(at,at,shape).is_empty()
	check(clear,"all cosmetic semi sections stay clear of truck at center and both road edges")
	fresh();item(0,.95);advance(.03)
	var count: int=game.world.contact_fx.get_child_count()
	for i in range(12):game.world.contact_burst(Vector3(0,1,-3),Vector3.FORWARD,2,3)
	check(game.world.contact_fx.get_child_count()==count and count==48,"repeated impacts reuse a bounded fragment pool")
	game.mode=game.Mode.PAUSED
	var frozen: Transform3D=game.world.hazard_nodes[0].transform
	game._simulate(.4);game.world._process(.4)
	check(frozen.is_equal_approx(game.world.hazard_nodes[0].transform),"pause freezes impacted debris")
	fresh()
	check(game.world.contact_fx.pieces.all(func(p):return not p.node.visible) and game.world.truck.recoil==Vector3.ZERO,"restart clears fragments and rigid recoil")
	var shelters=game.world.shelters
	check(shelters.sites.size()==4 and shelters.sites.all(func(s):return s.people.size()==3),"four ground shelters each have three articulated civilians")
	game.world.travel=0;game.elapsed=0;shelters.reset();shelters.update_view()
	var site: Dictionary=shelters.sites[0]
	check(site.root.visible and site.started,"nearby shelter evacuation starts as the truck approaches")
	var start: Vector3=site.people[0].node.position
	game.elapsed=1.3;shelters.update_view()
	check(site.people[0].node.position.distance_to(start)>1 and absf(site.people[0].limbs[0].rotation.x)>.05,"civilian travels toward entrance with running legs")
	var paused: Transform3D=site.people[0].node.transform;shelters.update_view()
	check(paused.is_equal_approx(site.people[0].node.transform),"civilian motion uses simulation time and freezes when paused")
	var shoulder_clear:=true
	for i in range(56):
		game.elapsed=i*.1;shelters.update_view()
		for p in site.people:shoulder_clear=shoulder_clear and absf((site.root.transform*p.node.position).x)>15.0
	check(shoulder_clear,"civilian paths remain well outside the road and truck envelope")
	check(site.inside==3 and site.people.all(func(p):return not p.node.visible),"all civilians disappear down the shelter entrance")
	check(site.closed and is_zero_approx(site.door.rotation.x),"shelter hatch closes only after everyone is inside")
	game.world.travel=120;shelters.update_view()
	check(not site.started,"streaming a shelter to the distance resets its evacuation")
	game.stage=5;game.route.enter(5);game.route.progress=350;game.world.travel=350;shelters.update_view()
	var grounded:=true
	for s in shelters.sites:
		if not s.root.visible:continue
		var p: Vector3=s.root.position
		grounded=grounded and absf(p.y-game.world._field_height(Vector2(p.x,p.z),shelters.samples))<.01
	check(grounded,"shelter foundations follow the off-road hill surface")
	game.stage=4;game.route.enter(4);game.route.progress=120;shelters.update_view()
	check(shelters.sites.all(func(s):return not s.root.visible),"shortcut junction stays clear of shelter sites")
	game.stage=7;game.route.enter(7);shelters.update_view()
	check(shelters.sites.all(func(s):return not s.root.visible),"civilians are absent from the tornado finale")
	print("SOLID_IMPACTS_TESTS ",checks," checks; ",failures," failures")
	game.queue_free();await process_frame;await create_timer(.1).timeout;quit(1 if failures else 0)
