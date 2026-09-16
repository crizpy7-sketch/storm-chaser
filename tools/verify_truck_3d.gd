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
func geometry(node: Node, result: Dictionary) -> void:
	if node is MeshInstance3D:
		result[str(node.get_path())]=hash(node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	for child in node.get_children():geometry(child,result)
func triangles(node: Node) -> int:
	# Mateo and optional Mateo Garage parts are not part of the approved truck mesh.
	if node.name=="MateoStormCamera" or node.has_meta("garage_part"):return 0
	var count:=0
	if node is MeshInstance3D:
		var a: Array=node.mesh.surface_get_arrays(0)
		count+=(a[Mesh.ARRAY_INDEX].size() if a[Mesh.ARRAY_INDEX]!=null else a[Mesh.ARRAY_VERTEX].size())/3
	for child in node.get_children():count+=triangles(child)
	return count
func run() -> void:
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"
	game=load("res://main.tscn").instantiate();game.settings_path="user://truck-3d-isolated.cfg"
	root.add_child(game);await process_frame
	game.save_enabled=false;game.start_chase();game.set_process(false);game.world.set_process(false);game.world.mateo.set_process(false)
	var rig=game.world.truck
	check(rig.artwork.get_aabb().size.z>5.0,"truck has full front-to-rear geometry")
	var count:=triangles(rig.model)
	check(count==67656,"all 67656 generated triangles survive mesh batching")
	check(rig.wheels.size()==4 and rig.wheels.all(func(w):return w.get_parent()==rig.model and w.get_parent()!=rig.body),"four independent wheels are outside the sprung-body transform")
	check(is_equal_approx(rig.wheels[0].position.distance_to(rig.wheels[2].position),3.54),"front and rear axles preserve the 3.54 metre wheelbase")
	check(rig.finish.get_shader_parameter("truck_art")==preload("res://assets/art/truck.png"),"original paint and panel art is reused on the 3D body")
	check(game.world.mateo.get_parent()==rig.body and game.world.mateo.position.z<2.65 and absf(game.world.mateo.position.x)<.9,"Mateo is attached inside the actual truck bed")
	var before: Dictionary={};geometry(rig.model,before)
	game.steer=1.0;game.rear_slip=0.0;game.glide_velocity=0.0
	for i in range(90):rig.step(1.0/60)
	check(rig.wheels[0].rotation.y<-.1 and rig.wheels[1].rotation.y<-.1,"right input visibly turns both front wheels right")
	check(is_zero_approx(rig.wheels[2].rotation.y) and is_zero_approx(rig.wheels[3].rotation.y),"rear wheels do not steer like the stock monster truck")
	var initial: float=rig.spin_angle
	rig.step(.031)
	check(absf(angle_difference(initial,rig.spin_angle))>.02,"distance rotates the actual wheel meshes")
	var saved_spin: float=rig.spin_angle;var saved_steering: float=rig.steering_angle
	rig.step(0.0)
	check(rig.spin_angle==saved_spin and rig.steering_angle==saved_steering,"zero-time updates freeze wheel articulation")
	game.route.grounded=false
	for i in range(90):rig.step(1.0/60)
	check(rig.wheels.all(func(w):return w.position.y<.55 and w.position.y>=.5399),"airborne wheels extend with bounded suspension droop")
	game.route.grounded=true;game.route.landings+=1;game.route.landing_severity=1.0
	var low:=0.0
	for i in range(30):rig.step(1.0/120);low=minf(low,rig.suspension)
	check(low<-.1 and low>=-.26,"landing compresses the rigid body within its suspension stops")
	for i in range(360):
		game.steer=sin(i*.05);game.rear_slip=game.steer*.8
		rig.rotation=Vector3(sin(i*.04)*.32,sin(i*.03)*.70,0)
		rig.step(1.0/60)
	var after: Dictionary={};geometry(rig.model,after)
	check(before==after,"steering, pitch, landings and yaw never change any mesh vertices")
	check(absf(rig.body.rotation.z)<=.0451 and rig.body.scale==Vector3.ONE,"chassis lean is bounded and never stretches the body")
	game.health=15;rig.apply_damage()
	check(rig.paint_finishes.size()>=3 and rig.paint_finishes.all(func(p):return is_equal_approx(p.get_shader_parameter("damage"),.85)),"hull damage reaches both original paint and new reference bodywork")
	rig.reset()
	check(rig.wheels.all(func(w):return is_equal_approx(w.position.y,.67) and w.rotation==Vector3.ZERO and w.get_node("Spin").rotation==Vector3.ZERO),"restart resets steering, spin and droop together")
	print("TRUCK_3D_TESTS ",checks," checks; ",failures," failures; ",count," triangles")
	game.queue_free();await process_frame;quit(1 if failures else 0)
