extends Node3D
# Independently rotating rigid sections; never stretch the original vehicle mesh.
var parts: Array[Node3D] = []
var fire: Node3D
var breakup := 0.0

static func make_template(source: Node3D, world) -> Node3D:
	var result:=Node3D.new()
	var groups: Array[Node3D]=[]
	var pivots: Array[Vector3]=[Vector3(0,2,-5.1),Vector3(0,1.2,2.6),Vector3(-1.2,.55,7.2),Vector3(1.2,.55,7.2)]
	for i in range(4):groups.append(Node3D.new())
	for child in source.get_children():
		var label:=str(child.name)
		if label.begins_with("Trailer box") or label.begins_with("Corrugated") or label.begins_with("Trailer doors") or label.begins_with("Door lock") or label.begins_with("Trailer upper") or label.begins_with("Trailer lower") or label.begins_with("Trailer marker"):continue
		var group:=0 if child.position.z < -3.35 else 1
		if child.position.z>6.0 and (label.begins_with("Wheel") or label.begins_with("Lug") or label.begins_with("Hub")):
			group=2 if child.position.x<0 else 3
		var copy: Node3D=child.duplicate();groups[group].add_child(copy);copy.position-=pivots[group]
	for i in range(4):
		var n: Node3D=world._bake_model(groups[i]);groups[i].free()
		n.name=["Tractor","TrailerFrame","LeftBogie","RightBogie"][i]
		n.position=pivots[i];result.add_child(n)
		_describe(n,i,Vector3(-2.5,1.7,-1.5) if i==0 else Vector3((i-2.5)*6,1.0,2.0),Vector3(.6,-.3,.45)*(i+1),.35 if i<2 else .48)
	var aluminum: Material=world.weathered(Color("aab5b2"),0,.55)
	# Thin corrugated walls replace the closed box, revealing a hollow cargo bay.
	for i in range(6):
		var side: float=-1.0 if i%2==0 else 1.0
		var p:=Vector3(side*1.29,2.98,-1.42+floori(i/2.0)*4.0)
		var src:=Node3D.new();world.box(src,Vector3.ZERO,Vector3(.075,3.2,3.98),aluminum)
		for rib in range(13):world.box(src,Vector3(side*.055,0,-1.84+rib*.3),Vector3(.055,3.18,.045),aluminum)
		var n: Node3D=world._bake_model(src);src.free();n.position=p;result.add_child(n)
		n.name="TornSide%02d"%i
		_describe(n,4+i,Vector3(side*(5+i*.4),2.8+(i%3),1.8),Vector3(.7,side*1.4,side*1.2),.28+i*.015)
	for i in range(3):
		var src:=Node3D.new();world.box(src,Vector3.ZERO,Vector3(2.58,.09,3.98),aluminum)
		var n: Node3D=world._bake_model(src);src.free();n.position=Vector3(0,4.60,-1.42+i*4.0);result.add_child(n)
		n.name="RoofSheet%02d"%i
		_describe(n,10+i,Vector3((i-1)*2.5,7+i*1.4,-1.5),Vector3(1.4,.6,i-.8),.20+i*.035)
	for i in range(2):
		var src:=Node3D.new();world.box(src,Vector3.ZERO,Vector3(1.27,3.15,.10),aluminum)
		world.box(src,Vector3(0,0,.10),Vector3(.045,2.8,.045),world.mat_steel)
		var n: Node3D=world._bake_model(src);src.free();n.position=Vector3(-.65+i*1.3,2.97,8.59);result.add_child(n)
		n.name="RearDoor%02d"%i
		_describe(n,13+i,Vector3((i-.5)*7,2.3,5.0),Vector3(.8,i*2-1,1.1),.42)
	var src:=Node3D.new()
	world.box(src,Vector3.ZERO,Vector3(2.5,.10,11.9),world.mat_wood)
	world.box(src,Vector3(0,1.56,-5.98),Vector3(2.5,3.15,.10),aluminum)
	var floor_node: Node3D=world._bake_model(src);src.free();floor_node.position=Vector3(0,1.4,2.6);result.add_child(floor_node)
	floor_node.name="CargoFloor";_describe(floor_node,15,Vector3(1.2,-1.0,2.3),Vector3(.3,.15,.12),.38)
	return result

static func _describe(n: Node3D, index: int, impulse: Vector3, spin: Vector3, release: float) -> void:
	n.set_meta("home",n.position);n.set_meta("impulse",impulse);n.set_meta("spin",spin);n.set_meta("release",release);n.set_meta("part",index)

func build(world) -> void:
	name="BreakingAirborneSemi"
	for original in world.semi_wreck_template.get_children():
		var p: Node3D=original.duplicate();add_child(p);parts.append(p)
	fire=Node3D.new();fire.set_script(preload("res://scripts/wreck_fire.gd"));add_child(fire)
	fire.build(.45,2.71,false)

func update_breakup(u: float, time: float, world) -> void:
	breakup=smoothstep(.20,.75,u)
	for part in parts:
		part.transform=part_transform(part,u)
		# Detail reductions never change the break-up path or the main silhouette.
		part.visible=not world.game.light_graphics or not str(part.name).begins_with("RearDoor")
	fire.position=parts[0].position+Vector3(.85,-.4,1.2)
	fire.visible=u>.30
	if fire.visible:fire.update_view(time,world.camera,world.game.light_graphics,world.game.calm_fx,smoothstep(.30,.52,u))

static func part_transform(part: Node3D, u: float) -> Transform3D:
	var t:=maxf(0,(u-float(part.get_meta("release")))*3.3)
	var ease:=t*t/(t+.15)
	var p: Vector3=part.get_meta("home")+part.get_meta("impulse")*ease+Vector3.DOWN*t*t*.7
	return Transform3D(Basis.from_euler(part.get_meta("spin")*ease),p)
