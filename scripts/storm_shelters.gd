extends Node3D
# Civilian routes and shelter entrances stay outside the entire driving corridor.
var game
var world
var sites: Array[Dictionary]=[]
var samples: Array[Vector3]=[]
var last_stage:=-1
var concrete: Material
var soil: Material
var steel: Material
var dark: Material
var skin: Material
var coats: Array[Material]=[]

func build() -> void:
	concrete=world.material(Color("989b8c"),0,.95)
	soil=world.material(Color("645b3d"),0,1.0)
	steel=world.material(Color("526b61"),.45,.64)
	dark=world.material(Color("202b2b"),0,.88)
	skin=world.material(Color("9c7c67"),0,.92)
	for color in ["b99b62","647e8a","98675b"]:coats.append(world.material(Color(color),0,.94))
	for i in range(4):
		var root:=Node3D.new();root.name="GroundShelter%02d"%i;add_child(root)
		var door:=_shelter(root)
		var people: Array[Dictionary]=[]
		for j in range(3):people.append(_civilian(j,root))
		sites.append({"root":root,"door":door,"people":people,"side":1.0 if i%2==0 else -1.0,"offset":112.0+i*170.0,"started":false,"start":0.0,"last_z":-700.0,"inside":0,"closed":false})

func _shelter(parent: Node3D) -> Node3D:
	# A berm with a dark recessed entrance, concrete retaining walls and stairs.
	var mound:=SphereMesh.new();mound.radius=2.75;mound.height=2.30;mound.radial_segments=16;mound.rings=8
	world.mesh_node(parent,mound,Vector3(0,-.45,-1.4),soil)
	world.box(parent,Vector3(-1.48,.44,.65),Vector3(.48,1.15,3.0),concrete)
	world.box(parent,Vector3(1.48,.44,.65),Vector3(.48,1.15,3.0),concrete)
	world.box(parent,Vector3(0,.02,1.55),Vector3(3.0,.16,1.4),concrete)
	world.box(parent,Vector3(0,.68,-.76),Vector3(2.7,1.75,.24),dark)
	for j in range(4):
		world.box(parent,Vector3(0,.03-j*.16,1.22-j*.42),Vector3(2.5,.14,.43),concrete)
	for x in [-1.1,1.1]:
		world.cylinder(parent,Vector3(x,.57,1.6),.042,1.05,steel)
		var rail: MeshInstance3D=world.cylinder(parent,Vector3(x,.82,.8),.045,1.9,steel);rail.rotation.x=PI*.5
	var hinge:=Node3D.new();parent.add_child(hinge);hinge.position=Vector3(0,.94,-.78)
	world.box(hinge,Vector3(0,0,1.40),Vector3(2.62,.12,2.8),steel)
	for x in [-.82,.82]:world.box(hinge,Vector3(x,.09,1.4),Vector3(.055,.08,2.6),concrete)
	world.box(hinge,Vector3(0,.16,2.38),Vector3(.4,.10,.065),dark)
	hinge.rotation.x=-1.25
	world.box(parent,Vector3(2.15,1.1,.5),Vector3(.10,2.2,.10),steel)
	world.box(parent,Vector3(2.15,2.1,.5),Vector3(2.9,.88,.10),world.material(Color("284e42"),0,.9))
	var sign:=Label3D.new();sign.text="STORM\nSHELTER";sign.font_size=42;sign.pixel_size=.017
	sign.position=Vector3(2.15,2.1,.57);sign.modulate=Color("d8e3c4");sign.outline_size=0
	parent.add_child(sign)
	world.box(parent,Vector3(-1.43,1.0,1.22),Vector3(.16,.22,.16),world.material(Color("8bce9f"),0,.5,.7))
	return hinge

func _capsule(parent: Node3D, p: Vector3, radius: float, height: float, mat: Material) -> void:
	var mesh:=CapsuleMesh.new();mesh.radius=radius;mesh.height=height;mesh.radial_segments=8;mesh.rings=4
	world.mesh_node(parent,mesh,p,mat)

func _civilian(index: int, parent: Node3D) -> Dictionary:
	var root:=Node3D.new();root.name="Civilian%02d"%index;parent.add_child(root)
	var torso:=Node3D.new();root.add_child(torso);torso.position.y=.94
	_capsule(torso,Vector3(0,.25,0),.23,.67,coats[index])
	_capsule(torso,Vector3(0,.78,-.055),.15,.34,skin)
	_capsule(torso,Vector3(0,.90,-.025),.151,.20,dark)
	var limbs: Array[Node3D]=[]
	var knees: Array[Node3D]=[]
	for side in [-1.0,1.0]:
		var leg:=Node3D.new();torso.add_child(leg);leg.position=Vector3(side*.135,0,0);limbs.append(leg)
		_capsule(leg,Vector3(0,-.21,0),.09,.44,dark)
		var knee:=Node3D.new();leg.add_child(knee);knee.position.y=-.42;knees.append(knee)
		_capsule(knee,Vector3(0,-.18,0),.075,.38,dark)
		world.box(knee,Vector3(0,-.38,-.07),Vector3(.16,.14,.29),dark)
	for side in [-1.0,1.0]:
		var arm:=Node3D.new();torso.add_child(arm);arm.position=Vector3(side*.26,.46,0);limbs.append(arm)
		_capsule(arm,Vector3(0,-.15,0),.074,.31,coats[index])
		var forearm:=Node3D.new();arm.add_child(forearm);forearm.position.y=-.28;forearm.rotation.x=-1.1
		_capsule(forearm,Vector3(0,-.12,0),.065,.29,coats[index])
		_capsule(forearm,Vector3(0,-.26,0),.061,.13,skin)
	return {"node":root,"torso":torso,"limbs":limbs,"knees":knees,"index":index,"inside":false}

func reset() -> void:
	last_stage=-1
	for s in sites:
		s.started=false;s.inside=0;s.closed=false;s.last_z=-700.0;s.door.rotation.x=-1.25
		for person in s.people:person.inside=false;person.node.show()

func update_view() -> void:
	if game.stage!=last_stage:reset();last_stage=game.stage
	samples.clear()
	for row in range(38):samples.append(world.surface_point(30.0-row*12.0))
	if game.stage in [4,5,6]:world._field_prepare(PackedVector3Array(samples))
	for s in sites:
		var z: float=32.0-fposmod(float(s.offset)-world.travel,680.0)
		if z<float(s.last_z)-200.0:s.started=false;s.inside=0;s.closed=false
		s.last_z=z
		s.root.visible=game.stage<7 and z> -205.0 and z<27.0
		if game.stage==4 and game.route.progress<285.0:s.root.hide()
		if not s.root.visible:continue
		var p: Vector3=world.surface_point(z,float(s.side)*18.0)
		p.y=world._field_height(Vector2(p.x,p.z),samples) if game.stage in [4,5,6] else -.06
		s.root.position=p;s.root.rotation.y=world.surface_rotation(z).y
		if not s.started and z> -160.0:
			s.started=true
			s.start=game.elapsed-clampf((160.0+z)/maxf(20.0,game.speed*.25),0.0,3.0)
		var age: float=maxf(0,game.elapsed-float(s.start)) if s.started else 0.0
		s.inside=0
		for person in s.people:
			var j: int=person.index
			var t:=maxf(0,age-j*.48)
			var u:=clampf(t/3.4,0,1)
			var start:=Vector3(float(s.side)*(8.4+j*.65),0,5.0+j*.5)
			var entrance:=Vector3((j-1)*.36,0,1.9)
			var local:=start.lerp(entrance,smoothstep(0,1,clampf(u/.78,0,1)))
			if u>.78:local=entrance.lerp(Vector3((j-1)*.36,-1.25,-.70),(u-.78)/.22)
			if game.stage in [4,5,6] and u<.78:
				var foot: Vector3=s.root.transform*local
				var ground: float=world._field_height(Vector2(foot.x,foot.z),samples)
				local.y=(ground-p.y)*(1.0-smoothstep(.64,.78,u))
			person.node.position=local
			var direction:=entrance-start if u<.78 else Vector3(0,0,-1)
			person.node.rotation.y=atan2(-direction.x,-direction.z)
			person.inside=u>=.985
			person.node.visible=not person.inside
			if person.inside:s.inside+=1
			var cycle:=t*12.8+j*.7
			person.torso.position.y=.94+absf(sin(cycle))*.065
			person.torso.rotation.x=-.17
			for k in range(2):
				person.limbs[k].rotation.x=sin(cycle+k*PI)*.67
				person.knees[k].rotation.x=maxf(0,-sin(cycle+k*PI))*.90
				person.limbs[k+2].rotation.x=-sin(cycle+k*PI)*.60-.24
		s.closed=s.inside==3 and age>5.1
		s.door.rotation.x=lerpf(-1.25,0,smoothstep(4.45,5.1,age))
