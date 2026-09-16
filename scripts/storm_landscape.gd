extends Node3D
# Road-relative streaming scenery. Geometry is built once and batched by material.
const Fire = preload("res://scripts/wreck_fire.gd")
var game
var world
var clusters: Array[Dictionary] = []
var fires: Array[Dictionary] = []
var wood: Material
var pale: Material
var brick: Material
var roof: Material
var dark: Material
var grass: MultiMesh
var grass_material: ShaderMaterial
var grass_bases: Array[Basis] = []
# Grass tufts keep one course position per scrolling cycle, so the hill levels only
# re-project them each frame; ground height comes from field_grass.gdshader.
var grass_cycle := PackedInt32Array()
var grass_course := PackedVector2Array()
var grass_height := PackedFloat64Array()
var grass_level := -1
var grass_on_field := false
var samples := PackedVector3Array()

func build() -> void:
	wood=_surface(Color("625340"),Vector2.ZERO,.0,.75)
	pale=_surface(Color("aca695"),Vector2.ZERO,.0,.34)
	brick=_surface(Color("7e6751"),Vector2(0,.5),.0,.55)
	roof=_surface(Color("576463"),Vector2(.5,0),.35,.42)
	dark=world.material(Color("252a24"),0,.94)
	for i in range(10):
		var root:=Node3D.new();root.name="RuinedHome%02d"%i;add_child(root)
		var loose: Array[Dictionary]=[]
		_house(root,i%3,loose)
		clusters.append({"root":root,"kind":"house","offset":i*53.0+32.0,"side":-1.0 if i%2==0 else 1.0,"lateral":22.0+(i%3)*7.0,"yaw":.17*sin(i*5.3),"loose":loose})
		if i%3==0:
			var fire:=Node3D.new();fire.set_script(Fire);root.add_child(fire)
			fire.position=Vector3(2.5,.05,4.7);fire.build(1.0,i*1.71)
			fires.append({"node":fire,"root":root})
	for i in range(36):
		var root:=Node3D.new();root.name="SplinteredTree%02d"%i;add_child(root)
		_tree(root,i%4)
		clusters.append({"root":root,"kind":"tree","offset":i*14.7+12.0,"side":-1.0 if i%2==0 else 1.0,"lateral":15.8+(i%5)*5.6,"yaw":i*2.399,"loose":[]})
	for i in range(14):
		var root:=Node3D.new();root.name="BrokenFence%02d"%i;add_child(root)
		_fence(root,i)
		clusters.append({"root":root,"kind":"fence","offset":i*38.0+15.0,"side":-1.0 if i%2==0 else 1.0,"lateral":10.5,"yaw":0.0,"loose":[]})
	_build_grass()

func _box(parent: Node3D, p: Vector3, s: Vector3, mat: Material) -> MeshInstance3D:
	return world.box(parent,p,s,mat)

func _surface(color: Color, tile: Vector2, metal: float, uv_scale: float) -> ShaderMaterial:
	var mat:=ShaderMaterial.new();mat.shader=preload("res://shaders/ruin_surface.gdshader")
	mat.set_shader_parameter("material_atlas",world.BUILDING_ART);mat.set_shader_parameter("tint",color)
	mat.set_shader_parameter("tile",tile);mat.set_shader_parameter("metal",metal);mat.set_shader_parameter("scale_uv",uv_scale)
	return mat

func _beam(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material, tapered: bool = false) -> void:
	var mesh:=CylinderMesh.new();mesh.bottom_radius=radius;mesh.top_radius=radius*(.52 if tapered else 1.0)
	mesh.height=a.distance_to(b);mesh.radial_segments=7
	var n: MeshInstance3D=world.mesh_node(parent,mesh,(a+b)*.5,mat)
	var direction:=(b-a).normalized();var cross:=Vector3.UP.cross(direction)
	if cross.length()>.001:n.basis=Basis(cross.normalized(),acos(clampf(Vector3.UP.dot(direction),-1,1)))

func _batch(source: Node3D, parent: Node3D) -> Node3D:
	var batched: Node3D=world._bake_model(source)
	parent.add_child(batched);source.free();return batched

func _house(parent: Node3D, variant: int, loose: Array[Dictionary]) -> void:
	var n:=Node3D.new()
	_box(n,Vector3(0,-.20,0),Vector3(10.2,.65,8.3),brick)
	_box(n,Vector3(0,.18,0),Vector3(9.8,.16,7.8),wood)
	# Open front windows and door: real gaps with visible framing and interior.
	for x in [-4.8,-2.7,-.95,1.0,2.8,4.7]:
		_box(n,Vector3(x,1.8,3.9),Vector3(.22,3.3,.20),pale)
	for band in range(15):
		var y:=.4+band*.21
		for section in range(5):
			var x:=-3.8+section*1.9
			if section==2 and band<11:continue
			if section in [0,3] and band in range(4,11):continue
			if section==4 and band>8-variant:continue
			_box(n,Vector3(x,y,3.96),Vector3(1.87,.20,.15),pale)
	_box(n,Vector3(-4.9,1.75,0),Vector3(.20,3.2,7.9),pale)
	_box(n,Vector3(0,1.2,-3.9),Vector3(9.8,2.1,.18),pale)
	for i in range(7):
		var z:=-3.5+i*1.15
		_box(n,Vector3(4.8,1.25,z),Vector3(.14,2.4+sin(i*2.2),.15),wood)
		_beam(n,Vector3(-5,3.5,z),Vector3(0,5.7,z),.09,wood)
		_beam(n,Vector3(0,5.7,z),Vector3(5,3.5,z),.09,wood)
		if i%2==0:_beam(n,Vector3(-4.8,3.45,z),Vector3(4.8,3.45,z),.07,wood)
	_box(n,Vector3(0,5.7,0),Vector3(.16,.19,8.2),wood)
	for x in [-3.8,1.9]:
		for y in [1.2,2.7]:_box(n,Vector3(x,y,4.09),Vector3(1.78,.13,.13),wood)
		_box(n,Vector3(x,1.97,4.09),Vector3(.085,1.6,.13),wood)
		shutter(n,Vector3(x+.84,2,4.15),.24+variant*.21)
	# Chimney and a partially collapsed porch give every house a readable silhouette.
	_box(n,Vector3(-2.9,3.3,-1.7),Vector3(.85,6.2,.95),brick)
	_box(n,Vector3(-2.9,6.45,-1.7),Vector3(1.0,.20,1.1),brick)
	_box(n,Vector3(0,.21,4.9),Vector3(4.5,.28,1.9),wood)
	for x in [-2.1,2.1]:
		var post:=_box(n,Vector3(x,1.35,5.5),Vector3(.15,2.6,.15),pale)
		post.rotation.z=.2 if x>0 else -.07
	var awning:=_box(n,Vector3(0,2.9,4.9),Vector3(4.6,.12,2.2),roof);awning.rotation.z=.16
	for i in range(16):
		var plank:=_box(n,Vector3(sin(i*4.7)*7.4,.28,cos(i*2.4)*5.0),Vector3(.20,.12,1.0+(i%4)*.5),wood if i%3 else pale)
		plank.rotation=Vector3(.14*sin(i),i*2.399,.10)
	_batch(n,parent)
	for i in range(6):
		var p:=Vector3((-1.0 if i%2==0 else 1.0)*2.6,4.64,-2.65+(i/2)*2.65)
		var part:=Node3D.new();parent.add_child(part);part.position=p
		var geom:=Node3D.new()
		_box(geom,Vector3.ZERO,Vector3(5.7,.11,2.60),roof)
		for rib in range(9):_box(geom,Vector3(0,.08,-1.15+rib*.29),Vector3(5.65,.055,.045),roof)
		_batch(geom,part)
		part.rotation.z= .41 if i%2==0 else -.41
		loose.append({"node":part,"home":p,"rotation":part.rotation,"index":i})

func shutter(parent: Node3D, p: Vector3, tilt: float) -> void:
	var n:=_box(parent,p,Vector3(.5,1.6,.09),roof);n.rotation.z=tilt

func _tree(parent: Node3D, variant: int) -> void:
	var n:=Node3D.new()
	var height:=3.4+variant*.65
	_beam(n,Vector3(0,-.35,0),Vector3(.24,height,0),.38,wood,true)
	for i in range(6):
		var a:=i*TAU/6.0
		_beam(n,Vector3(sin(a)*.27,height-.2,cos(a)*.27),Vector3(sin(a)*.23,height+.25+fmod(i*.71,.65),cos(a)*.23),.10,pale,true)
	for i in range(5):
		var a:=i*2.399
		_beam(n,Vector3(0,.1,0),Vector3(sin(a)*1.4,-.05,cos(a)*1.4),.14,wood,true)
		var start:=Vector3(.12,1.4+i*.4,0)
		var end:=start+Vector3(sin(a)*1.6,.7,cos(a)*1.6)
		_beam(n,start,end,.12,wood,true)
		_beam(n,end,end+Vector3(cos(a)*.7,.6,sin(a)*.6),.05,wood,true)
	# Fallen crown, still visibly connected to the splintered trunk.
	var base:=Vector3(.2,.40,1.4)
	var end:=Vector3(3.8+variant*.35,1.0,4.5)
	_beam(n,base,end,.30,wood,true)
	for i in range(8):
		var start:=base.lerp(end,.2+i*.09)
		var tip:=start+Vector3(sin(i*3.1)*1.7,.4+(i%3)*.45,cos(i*2.4)*1.8)
		_beam(n,start,tip,.095,wood,true)
		_beam(n,tip,tip+Vector3(.5,.6,.35),.045,wood,true)
	_batch(n,parent)

func _fence(parent: Node3D, variant: int) -> void:
	var n:=Node3D.new()
	for i in range(5):
		var p:=_box(n,Vector3(.0,.70,i*2.7-5.4),Vector3(.17,1.4,.17),wood)
		p.rotation.z=sin(i*3.0+variant)*.28
		if i==4:continue
		for y in [.45,1.1]:
			var rail:=_box(n,Vector3(.04,y,i*2.7-4.05),Vector3(.11,.12,2.72),pale)
			if i==variant%4:rail.rotation.x=.5;rail.position.y-=.36
	_batch(n,parent)

func _build_grass() -> void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(9):
		var p:=Vector3(sin(i*2.399)*.55,0,cos(i*2.399)*.55)
		for v in [p+Vector3(-.055,0,0),p+Vector3(.055,0,0),p+Vector3(.28,.45+(i%3)*.13,.14)]:
			st.set_normal(Vector3.BACK);st.add_vertex(v)
	grass_material=ShaderMaterial.new();grass_material.shader=preload("res://shaders/field_grass.gdshader")
	grass_material.set_shader_parameter("grass_color",Color("555738"))
	grass=MultiMesh.new();grass.transform_format=MultiMesh.TRANSFORM_3D;grass.mesh=st.commit();grass.instance_count=320
	var node:=MultiMeshInstance3D.new();node.multimesh=grass;node.material_override=grass_material
	# Hill heights are applied in the shader, so culling uses the full corridor height.
	node.custom_aabb=AABB(Vector3(-60,-90,-250),Vector3(120,170,290))
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(node)
	for i in range(320):grass_bases.append(Basis(Vector3.UP,i*2.399).scaled(Vector3.ONE*(.65+fmod(i*.41,1.1))))
	grass_cycle.resize(320);grass_course.resize(320);grass_height.resize(320)

func _ground(p: Vector3) -> float:
	return world.field_height_at(p.x,p.z) if game.stage in [4,5,6] else -.06

func update_view() -> void:
	var time: float=game.elapsed
	samples.clear()
	for row in range(38):samples.append(world.surface_point(30.0-row*12.0))
	if game.stage in [4,5,6]:world._field_prepare(samples)
	for i in range(clusters.size()):
		var c: Dictionary=clusters[i];var node: Node3D=c.root
		var z: float=32.0-fposmod(float(c.offset)-world.travel,530.0)
		node.visible=z>-350.0 and z<28.0 and game.stage<7
		if game.light_graphics and c.kind=="tree" and i%2==1:node.visible=false
		# Keep the actual perpendicular shortcut junction open.
		if game.stage==4 and game.route.progress<285.0 and z>game.route.progress-285.0:node.visible=false
		if not node.visible:continue
		var p: Vector3=world.surface_point(z,float(c.side)*float(c.lateral))
		p.y=_ground(p);node.position=p
		node.rotation=Vector3(0,world.surface_rotation(z).y+float(c.yaw),0)
		if c.kind=="tree":node.rotation.z=sin(time*1.9+i)*.012
		for loose in c.loose:
			var part: Node3D=loose.node;var idx: int=loose.index
			var release:=smoothstep(-145.0-idx*4.0,-75.0-idx*4.0,z)
			var displacement:=Vector3(float(c.side)*(2.5+idx)*release,release*release*(9+idx*2),-release*(7+idx*1.8))
			part.position=loose.home+displacement
			part.rotation=loose.rotation+Vector3(release*(idx*.5+.8),release*.7,release*float(c.side)*1.7)
			part.visible=release<.995 or z< -45
	for f in fires:
		if f.root.visible:f.node.update_view(time,world.camera,game.light_graphics,game.calm_fx)
	grass.visible_instance_count=160 if game.light_graphics else 320
	var hills: bool=game.stage in [4,5,6]
	if hills!=grass_on_field:
		grass_on_field=hills;grass_material.set_shader_parameter("terrain_field",hills)
	var hidden: bool=game.stage==7 or (game.stage==4 and game.route.progress<285)
	var cached: bool=hills and game.route.active and world.travel==game.route.progress
	if grass_level!=game.route.level or not cached:
		grass_level=game.route.level if cached else -1
		grass_cycle.fill(-2147483648)
	for i in range(grass.visible_instance_count):
		if hidden:
			grass.set_instance_transform(i,Transform3D(Basis().scaled(Vector3.ZERO),Vector3.ZERO))
			continue
		var along: float=i*1.27-world.travel
		var z:=24.0-fposmod(along,260.0)
		var lateral:=(-1.0 if i%2==0 else 1.0)*(9.7+fmod(i*3.79,35.0))
		var p: Vector3
		if cached:
			var cycle:=floori(along/260.0)
			if grass_cycle[i]!=cycle:
				var s: float=game.route.progress-z
				var heading: float=game.route.heading(s)
				grass_cycle[i]=cycle
				grass_course[i]=game.route.course(s)+Vector2(cos(heading),sin(heading))*lateral
				grass_height[i]=game.route.height_at(s)
			# Road-relative height; field_grass.gdshader lifts each tuft onto the hills.
			p=game.route.project_point(grass_course[i],grass_height[i])
		else:
			p=world.surface_point(z,lateral)
			p.y=_ground(p)
		grass.set_instance_transform(i,Transform3D(grass_bases[i],p))
