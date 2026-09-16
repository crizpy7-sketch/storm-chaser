extends SceneTree
## Original, editable mesh construction. No paid models or reconstructed flat shells.
## X right, Y up, -Z forward; independent wheel pivots are in vehicle metres.

const ART = preload("res://assets/art/truck.png")
const REFERENCE = preload("res://assets/art/interceptor-reference.jpeg")
var vehicle: Node3D
var shell: Node3D
var materials: Dictionary = {}
var batches: Dictionary = {}
var total_triangles := 0
var orange_patch := Rect2(.285,.604,.17,.078)
var steel_patch := Rect2(.396,.752,.055,.039)

func _initialize() -> void:
	call_deferred("build")

func material(label: String, color: Color, metallic: float, roughness: float, textured := false, emission := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = label
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if textured: m.albedo_texture = ART
	if emission > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	materials[label] = m
	return m

func group(label: String, parent: Node3D, pos := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.name = label
	parent.add_child(n)
	n.position = pos
	return n

func surface(parent: Node3D, mat: Material) -> SurfaceTool:
	var key := str(parent.get_instance_id())+"/"+mat.resource_name
	if not batches.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		batches[key] = {"parent":parent,"material":mat,"surface":st}
	return batches[key].surface

func tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, uva := Vector2.ZERO, uvb := Vector2.RIGHT, uvc := Vector2.ONE) -> void:
	var points := [a,b,c]
	var norms := [na,nb,nc]
	var uvs := [uva,uvb,uvc]
	var order := [0,2,1] if (b-a).cross(c-a).dot(na+nb+nc) > 0 else [0,1,2]
	for idx in order:
		st.set_normal(norms[idx]);st.set_uv(uvs[idx]);st.add_vertex(points[idx])
	total_triangles += 1

func quad(parent: Node3D, vertices: Array, mat: Material, uvrect := Rect2(0,0,1,1), flip := false) -> void:
	var st := surface(parent,mat)
	var n: Vector3 = (vertices[1]-vertices[0]).cross(vertices[2]-vertices[0]).normalized()
	if flip:n=-n
	var uvs := [uvrect.position,uvrect.position+Vector2(uvrect.size.x,0),uvrect.end,uvrect.position+Vector2(0,uvrect.size.y)]
	tri(st,vertices[0],vertices[1],vertices[2],n,n,n,uvs[0],uvs[1],uvs[2])
	tri(st,vertices[0],vertices[2],vertices[3],n,n,n,uvs[0],uvs[2],uvs[3])

func box(parent: Node3D, center: Vector3, size: Vector3, mat: Material, bevel := .035, rotation := Vector3.ZERO, uvrect := Rect2(.285,.604,.17,.078)) -> void:
	if mat.resource_name=="All terrain rubber":uvrect=Rect2(.171,.814,.038,.080)
	if mat.resource_name=="Equipment black":uvrect=Rect2(.316,.498,.128,.049)
	if mat.resource_name=="Equipment olive":uvrect=Rect2(.516,.493,.055,.06)
	var h := size*.5
	var radius := minf(bevel,minf(h.x,minf(h.y,h.z))*.75)
	var inner := h-Vector3.ONE*radius
	var basis := Basis.from_euler(rotation)
	var st := surface(parent,mat)
	if bevel <= .013:
		for axis in range(3):
			var u: int=(axis+1)%3;var v: int=(axis+2)%3
			for side in [-1,1]:
				var ps: Array[Vector3]=[];var ts: Array[Vector2]=[]
				var n:=Vector3.ZERO;n[axis]=side;n=basis*n
				for uv in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
					var p:=Vector3.ZERO;p[axis]=side*h[axis];p[u]=(uv.x*2-1)*h[u];p[v]=(uv.y*2-1)*h[v]
					ps.append(center+basis*p);ts.append(uvrect.position+uv*uvrect.size)
				tri(st,ps[0],ps[1],ps[2],n,n,n,ts[0],ts[1],ts[2]);tri(st,ps[0],ps[2],ps[3],n,n,n,ts[0],ts[2],ts[3])
		return
	# Rounded edges are actual geometry, with continuous corner normals.
	for axis in range(3):
		var u := (axis+1)%3
		var v := (axis+2)%3
		var us := [-h[u],-inner[u],inner[u],h[u]]
		var vs := [-h[v],-inner[v],inner[v],h[v]]
		for side in [-1,1]:
			for i in range(3):
				for j in range(3):
					var ps: Array[Vector3]=[]
					var ns: Array[Vector3]=[]
					var ts: Array[Vector2]=[]
					for offset in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
						var p := Vector3.ZERO
						p[axis]=side*h[axis];p[u]=us[i+offset.x];p[v]=vs[j+offset.y]
						var nearest := p.clamp(-inner,inner)
						var normal := (p-nearest).normalized()
						ps.append(center+basis*(nearest+normal*radius))
						ns.append(basis*normal)
						ts.append(uvrect.position+Vector2((p[u]/h[u]+1)*.5,(1-p[v]/h[v])*.5)*uvrect.size)
					tri(st,ps[0],ps[1],ps[2],ns[0],ns[1],ns[2],ts[0],ts[1],ts[2])
					tri(st,ps[0],ps[2],ps[3],ns[0],ns[2],ns[3],ts[0],ts[2],ts[3])

func tube(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material, top_radius := -1.0, segments := 12) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius=radius;mesh.top_radius=radius if top_radius<0 else top_radius
	mesh.height=a.distance_to(b);mesh.radial_segments=segments;mesh.rings=1
	var y: Vector3=(b-a).normalized()
	var x: Vector3=y.cross(Vector3.FORWARD if absf(y.z)<.9 else Vector3.RIGHT).normalized()
	var z: Vector3=x.cross(y).normalized()
	# Feed every primitive through the same non-indexed triangle stream. Mixing
	# append_from's indices with raw vertices silently drops later box faces.
	var transform:=Transform3D(Basis(x,y,z),(a+b)*.5)
	var arrays:=mesh.get_mesh_arrays()
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var st:=surface(parent,mat)
	for i in range(0,indices.size(),3):
		var ia:=indices[i];var ib:=indices[i+1];var ic:=indices[i+2]
		tri(st,transform*vertices[ia],transform*vertices[ib],transform*vertices[ic],transform.basis*normals[ia],transform.basis*normals[ib],transform.basis*normals[ic],uvs[ia],uvs[ib],uvs[ic])

func ring(parent: Node3D, center: Vector3, major: float, minor: float, mat: Material, axis := 0, steps := 40, sides := 8) -> void:
	var st := surface(parent,mat)
	for i in range(steps):
		for j in range(sides):
			var ps: Array[Vector3]=[];var ns: Array[Vector3]=[];var uvs: Array[Vector2]=[]
			for offset in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
				var a: float=(i+offset.x)*TAU/steps
				var b: float=(j+offset.y)*TAU/sides
				var n:=Vector3(sin(b),cos(a)*cos(b),sin(a)*cos(b))
				var p:=Vector3(minor*sin(b),(major+minor*cos(b))*cos(a),(major+minor*cos(b))*sin(a))
				if axis==1:
					p=Vector3(p.y,p.x,p.z);n=Vector3(n.y,n.x,n.z)
				ps.append(center+p);ns.append(n)
				uvs.append(Vector2(.171,.814)+Vector2(a/TAU,b/TAU)*Vector2(.038,.080) if mat.resource_name=="All terrain rubber" else Vector2(a/TAU,b/TAU))
			tri(st,ps[0],ps[1],ps[2],ns[0],ns[1],ns[2],uvs[0],uvs[1],uvs[2])
			tri(st,ps[0],ps[2],ps[3],ns[0],ns[2],ns[3],uvs[0],uvs[2],uvs[3])

func fender(parent: Node3D, side: float, z_center: float) -> void:
	curved_surface(parent,materials["Graphite armor"],func(u: float,v: float)->Vector3:
		var a: float=lerpf(-.04,PI+.04,u)
		var r: float=lerpf(.747,.847,v)
		var x: float=1.155+.128*sin(v*PI*.85)
		return Vector3(side*x,.67+sin(a)*r,z_center+cos(a)*r),
		func(_p: Vector3,u: float,v: float)->Vector2:return Vector2(u,v),48,8,Vector3(side,0,0))

func build_wheel(label: String, pos: Vector3) -> void:
	var pivot:=group(label,vehicle,pos)
	var spin:=group("Spin",pivot)
	var rubber: Material=materials["All terrain rubber"]
	var metal: Material=materials["Graphite armor"]
	# Rounded tire carcass plus large alternating tread blocks.
	ring(spin,Vector3.ZERO,.452,.184,rubber,0,48,10)
	for side in [-1,1]:
		ring(spin,Vector3(side*.205,0,0),.399,.035,rubber,0,40,6)
		ring(spin,Vector3(side*.218,0,0),.294,.025,materials["Fasteners"],0,40,6)
		tube(spin,Vector3(side*.160,0,0),Vector3(side*.208,0,0),.295,metal,-1,32)
		tube(spin,Vector3(side*.21,0,0),Vector3(side*.262,0,0),.107,metal,-1,12)
		for spoke in range(6):
			var angle: float=spoke*TAU/6
			box(spin,Vector3(side*.227,sin(angle)*.172,cos(angle)*.172),Vector3(.048,.061,.246),metal,.012,Vector3(-angle,0,0))
			var p:=Vector3(side*.269,sin(angle)*.071,cos(angle)*.071)
			tube(spin,p,p+Vector3(side*.015,0,0),.016,materials["Fasteners"],-1,8)
		for bolt in range(16):
			var angle: float=bolt*TAU/16
			var p:=Vector3(side*.226,sin(angle)*.282,cos(angle)*.282)
			tube(spin,p,p+Vector3(side*.012,0,0),.010,materials["Fasteners"],-1,6)
	for i in range(32):
		var angle: float=i*TAU/32
		for band in [-1,1]:
			var a: float=angle+band*.023
			box(spin,Vector3(band*.115,cos(a)*.612,sin(a)*.612),Vector3(.235,.065,.105),rubber,.013,Vector3(a,band*.38,0))
		box(spin,Vector3(0,cos(angle+.045)*.629,sin(angle+.045)*.629),Vector3(.098,.051,.079),rubber,.007,Vector3(angle+.045,0,0))

func reference_uv(p: Vector3) -> Vector2:
	# Project the supplied side elevation onto real curved panels at vehicle scale.
	var px:=clampf(1090.0+(p.z+1.77)*147.46,998.0,1750.0)
	var py: float=381.0-(p.y-.67)*153.0 if p.y<=1.68 else 226.47-(p.y-1.68)*110.0
	if p.z>.93:py=381.0-(p.y-.67)*138.0
	# Keep the atlas projection inside the photographed sheet-metal silhouette.
	var top:=152.0
	if px<1100:top=lerpf(238,222,clampf((px-998)/102,0,1))
	elif px<1170:top=222.0
	elif px<1290:top=lerpf(222,151,(px-1170)/120)
	elif px>1475:top=230.0
	py=maxf(py,top+3.0)
	return Vector2(px,py)/Vector2(1792,1008)

func side_point(u: float, v: float, side: float) -> Vector3:
	var z:=lerpf(-2.68,2.77,u)
	var bottom:=.79
	for axle in [-1.77,1.77]:
		var d: float=absf(z-axle)
		if d<.755:bottom=maxf(bottom,.67+sqrt(.755*.755-d*d))
	var top:=1.70 if z<.88 else 1.765
	if z < -1.25:top=lerpf(1.525,1.70,inverse_lerp(-2.68,-1.25,z))
	var y:=lerpf(bottom,top,v)
	var waist: float=sin(clampf((y-.79)/.94,0,1)*PI)
	var arch: float=maxf(exp(-pow((z+1.77)/.65,2)),exp(-pow((z-1.77)/.65,2)))
	var x: float=1.078+.074*waist+.10*arch*sin(v*PI)+.026*v
	x-=.095*pow(clampf((-z-2.42)/.26,0,1),2)
	return Vector3(side*x,y,z)

func curved_surface(parent: Node3D, mat: Material, point: Callable, uv: Callable, nu: int, nv: int, outward: Vector3) -> void:
	var st:=surface(parent,mat)
	for i in range(nu):
		for j in range(nv):
			var ps: Array[Vector3]=[];var ns: Array[Vector3]=[];var ts: Array[Vector2]=[]
			for ij in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
				var u: float=(i+ij.x)/float(nu);var v: float=(j+ij.y)/float(nv)
				var p: Vector3=point.call(u,v)
				var du: Vector3=point.call(minf(1,u+.0001),v)-point.call(maxf(0,u-.0001),v)
				var dv: Vector3=point.call(u,minf(1,v+.0001))-point.call(u,maxf(0,v-.0001))
				var n:=du.cross(dv).normalized()
				if n.dot(outward)<0:n=-n
				ps.append(p);ns.append(n);ts.append(uv.call(p,u,v))
			tri(st,ps[0],ps[1],ps[2],ns[0],ns[1],ns[2],ts[0],ts[1],ts[2])
			tri(st,ps[0],ps[2],ps[3],ns[0],ns[2],ns[3],ts[0],ts[2],ts[3])

func cab_width(y: float, z: float) -> float:
	var t:=clampf((y-1.64)/.72,0,1)
	return 1.105-.165*t+.035*sin(t*PI)-.026*pow(clampf(absf(z-.07)/.88,0,1),4)

func cab_panel(side: float, outline: Array, mat: Material, inset := .0, radius := .16) -> void:
	var points: Array[Vector3]=[]
	for i in range(outline.size()):
		var c: Vector2=outline[i]
		var a: Vector2=c.lerp(outline[(i+outline.size()-1)%outline.size()],radius)
		var b: Vector2=c.lerp(outline[(i+1)%outline.size()],radius)
		for j in range(9):
			var t: float=j/8.0
			var v: Vector2=a.lerp(c,t).lerp(c.lerp(b,t),t)
			points.append(Vector3(side*(cab_width(v.y,v.x)+inset),v.y,v.x))
	var center:=Vector3.ZERO
	for p in points:center+=p
	center/=points.size()
	center.x=side*(cab_width(center.y,center.z)+inset)
	# Radial subdivisions follow the compound curve instead of one flat fan.
	for i in range(points.size()):
		for k in range(6):
			var ps: Array[Vector3]=[];var ns: Array[Vector3]=[]
			for ij in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
				var p: Vector3=center.lerp(points[(i+ij.x)%points.size()],(k+ij.y)/6.0)
				p.x=side*(cab_width(p.y,p.z)+inset)
				var dy: float=(cab_width(p.y+.0001,p.z)-cab_width(p.y-.0001,p.z))/.0002
				var dz: float=(cab_width(p.y,p.z+.0001)-cab_width(p.y,p.z-.0001))/.0002
				ps.append(p);ns.append(Vector3(side,-dy,-dz).normalized())
			tri(surface(shell,mat),ps[0],ps[1],ps[2],ns[0],ns[1],ns[2],reference_uv(ps[0]),reference_uv(ps[1]),reference_uv(ps[2]))
			tri(surface(shell,mat),ps[0],ps[2],ps[3],ns[0],ns[2],ns[3],reference_uv(ps[0]),reference_uv(ps[2]),reference_uv(ps[3]))

func modern_body() -> void:
	var orange: Material=materials["Original orange patina"]
	var paint: Material=materials["Reference bodywork"]
	var glazing: Material=materials["Reference glazing"]
	var black: Material=materials["Graphite armor"]
	var lamps: Material=materials["White lamps"]
	var photo_uv:=func(p: Vector3,_u: float,_v: float)->Vector2:return reference_uv(p)
	for side in [-1.0,1.0]:
		curved_surface(shell,paint,func(u: float,v: float)->Vector3:return side_point(u,v,side),photo_uv,112,12,Vector3(side,0,0))
		# Broad painted shoulders flow into the actual cut-out wheel arches.
		for z in [-1.77,1.77]:
			fender(shell,side,z)
			# Recessed wheel tubs occlude daylight behind the suspended tires.
			curved_surface(shell,black,func(u: float,v: float)->Vector3:
				var angle: float=u*PI
				return Vector3(side*.87,.67+sin(angle)*v*.78,z+cos(angle)*v*.78),
				func(_p: Vector3,u: float,v: float)->Vector2:return Vector2(u,v),40,8,Vector3(side,0,0))
			curved_surface(shell,black,func(u: float,v: float)->Vector3:
				var angle: float=u*PI
				return Vector3(side*lerpf(.87,1.20,v),.67+sin(angle)*.77,z+cos(angle)*.77),
				func(_p: Vector3,u: float,v: float)->Vector2:return Vector2(u,v),40,4,Vector3.UP)
		cab_panel(side,[Vector2(-1.27,1.635),Vector2(-.56,2.35),Vector2(.72,2.35),Vector2(.94,1.635)],paint,0.0,.13)
		cab_panel(side,[Vector2(-1.15,1.735),Vector2(-.525,2.25),Vector2(.10,2.25),Vector2(.10,1.735)],glazing,.007,.16)
		cab_panel(side,[Vector2(.20,1.735),Vector2(.20,2.25),Vector2(.655,2.25),Vector2(.805,1.735)],glazing,.007,.18)
		# Slim modern mirror housings and recessed door handles.
		tube(shell,Vector3(side*1.08,1.70,-.80),Vector3(side*1.27,1.78,-.83),.031,black)
		box(shell,Vector3(side*1.30,1.81,-.82),Vector3(.26,.23,.20),black,.085)
		box(shell,Vector3(side*1.30,1.81,-.711),Vector3(.20,.165,.015),materials["Tinted glass"],.045)
		for z in [-.22,.65]:box(shell,Vector3(side*1.139,1.515,z),Vector3(.038,.050,.177),black,.020)
		# Bed has a continuous curved outer skin, inside wall and a soft rail cap.
		box(shell,Vector3(side*.99,1.49,1.84),Vector3(.08,.43,1.77),black,.022)
		box(shell,Vector3(side*1.075,1.764,1.85),Vector3(.235,.062,1.82),black,.026)
	box(shell,Vector3(0,.66,-2.16),Vector3(1.78,.095,1.08),black,.038,Vector3(-.14,0,0))
	# Crown-shaped roof; the former rectangular slab has been removed.
	curved_surface(shell,orange,func(u: float,v: float)->Vector3:
		var x: float=(u*2-1)*.945
		return Vector3(x,2.335+.060*sin(v*PI)*(1-pow(u*2-1,2))-.022*pow(absf(u*2-1),6),lerpf(-.58,.78,v)),
		func(_p: Vector3,u: float,v: float)->Vector2:return orange_patch.position+Vector2(u,v)*orange_patch.size,32,24,Vector3.UP)
	# Bowed glass with a curved upper edge, not an upright rectangular window.
	curved_surface(shell,glazing,func(u: float,v: float)->Vector3:
		var t: float=u*2-1
		return Vector3(t*lerpf(1.065,.925,v),lerpf(1.665,2.31,v)+.018*(1-t*t),lerpf(-1.275,-.565,v)-.048*(1-t*t)*sin(v*PI)),
		func(_p: Vector3,u: float,v: float)->Vector2:return Vector2(235+(u*2-1)*lerpf(122,93,v),216-v*58)/Vector2(1792,1008),32,20,Vector3.FORWARD)
	# Windshield seals and A pillars follow the same rake as the glass.
	for side in [-1,1]:
		tube(shell,Vector3(side*1.065,1.665,-1.275),Vector3(side*.925,2.31,-.565),.027,black,-1,12)
		tube(shell,Vector3(side*1.088,1.665,-1.252),Vector3(side*.955,2.31,-.541),.032,materials["Clean orange edges"],-1,12)
	quad(shell,[Vector3(.925,2.31,.76),Vector3(-.925,2.31,.76),Vector3(-1.075,1.66,.935),Vector3(1.075,1.66,.935)],materials["Tinted glass"])
	# Bonnet blends its curved nose, center crown and fender shoulders.
	curved_surface(shell,orange,func(u: float,v: float)->Vector3:
		var t: float=u*2-1
		var y: float=lerpf(1.565,1.715,v)+.030*(1-t*t)-.060*pow(absf(t),6)
		return Vector3(t*lerpf(1.035,1.10,v),y,lerpf(-2.735,-1.275,v)+.048*t*t),
		func(_p: Vector3,u: float,v: float)->Vector2:return Rect2(.275,.597,.205,.112).position+Vector2(u,v)*Vector2(.205,.112),40,28,Vector3.UP)
	# Curved fascia projected from the original front elevation. The corners
	# wrap back around the body, and the grille is physically recessed.
	curved_surface(shell,materials["Reference fascia"],func(u: float,v: float)->Vector3:
		var t: float=u*2-1
		var width: float=1.095-.018*cos(v*PI*2)
		var recess: float=.018*(1-pow(absf(t),2))
		return Vector3(t*width,lerpf(.99,1.555,v),-2.74+.13*pow(absf(t),5)+recess),
		func(p: Vector3,_u: float,_v: float)->Vector2:return Vector2(235+p.x*137.0,321.0-(p.y-.99)*125.0)/Vector2(1792,1008),48,24,Vector3.FORWARD)
	# Sculpted steel bumper with swept ends; small protected fog lamps.
	box(shell,Vector3(0,.88,-2.755),Vector3(1.42,.205,.27),black,.078)
	for side in [-1,1]:
		box(shell,Vector3(side*.92,.945,-2.69),Vector3(.70,.235,.30),black,.083,Vector3(0,-side*.19,side*.095))
		box(shell,Vector3(side*.85,.968,-2.861),Vector3(.115,.078,.016),lamps,.015)
		tube(shell,Vector3(side*.64,1.01,-2.893),Vector3(side*.48,1.10,-2.90),.033,black)
		tube(shell,Vector3(side*.48,1.10,-2.90),Vector3(0,1.10,-2.90),.033,black)
		# LED segments are fine accents; textured lamp interiors retain depth.
		for y in [1.157,1.486]:box(shell,Vector3(side*.937,y,-2.697),Vector3(.168,.009,.007),lamps,.003)

func build() -> void:
	vehicle=Node3D.new();vehicle.name="Interceptor3D";root.add_child(vehicle)
	shell=group("SprungBody",vehicle)
	material("Original orange patina",Color(.78,.80,.83),.13,.69,true)
	material("Clean orange edges",Color("c57824"),.28,.47)
	material("Graphite armor",Color("25282a"),.56,.49)
	material("Textured graphite",Color(.77,.80,.81),.46,.58,true)
	material("All terrain rubber",Color(.65,.67,.68),0,.95,true)
	material("Tinted glass",Color("1c3036"),.62,.18)
	material("Fasteners",Color("67706f"),.68,.43)
	material("Dish aluminum",Color("929a97"),.74,.38)
	material("Equipment olive",Color(.72,.72,.72),.12,.83,true)
	material("Equipment black",Color(.66,.69,.69),.08,.81,true)
	material("Canvas straps",Color("554633"),0,.94)
	material("Amber beacons",Color("ff8410"),.12,.23,false,.22)
	material("Brake lamps",Color("be160b"),.05,.27,false,.16)
	material("White lamps",Color("d7e2d8"),.07,.25,false,.28)
	for spec in [["Reference bodywork",.12,.56],["Reference fascia",.20,.42],["Reference glazing",.24,.22]]:
		var m:=material(spec[0],Color(.86,.87,.88),spec[1],spec[2])
		m.albedo_texture=REFERENCE
		m.clearcoat_enabled=true;m.clearcoat=.38;m.clearcoat_roughness=.25
	var orange: Material=materials["Original orange patina"]
	var black: Material=materials["Graphite armor"]
	var edge: Material=materials["Clean orange edges"]
	var bolts: Material=materials["Fasteners"]
	var glass: Material=materials["Tinted glass"]
	# Long frame rails, separate axles and differential housings.
	for side in [-1,1]:
		box(shell,Vector3(side*.64,.57,0),Vector3(.13,.22,5.2),black,.025)
		box(shell,Vector3(side*1.21,.69,-.10),Vector3(.18,.10,2.29),black,.035)
		for z in [-.78,.45]:tube(shell,Vector3(side*.92,.63,z),Vector3(side*1.25,.7,z),.035,black)
	for z in [-1.77,1.77]:
		tube(shell,Vector3(-1.20,.56,z),Vector3(1.20,.56,z),.077,black)
		box(shell,Vector3(0,.56,z),Vector3(.45,.34,.32),black,.12)
		for side in [-1,1]:
			tube(shell,Vector3(side*.81,.52,z),Vector3(side*.98,1.18,z-.16),.045,bolts)
	box(shell,Vector3(0,.99,-.23),Vector3(1.96,.25,2.55),black,.045)
	box(shell,Vector3(0,1.12,1.71),Vector3(2.03,.14,2.12),black,.025)
	modern_body()
	# Actual tailgate volume. Its outer face uses the original truck's tailgate pixels.
	var gate:=group("Tailgate",shell)
	box(gate,Vector3(0,1.427,2.722),Vector3(2.04,.696,.146),orange,.041)
	quad(gate,[Vector3(-1.006,1.754,2.80),Vector3(1.006,1.754,2.80),Vector3(1.006,1.10,2.80),Vector3(-1.006,1.10,2.80)],orange,Rect2(.248,.580,.482,.152),true)
	box(gate,Vector3(0,1.789,2.733),Vector3(2.04,.062,.20),black,.018)
	box(gate,Vector3(0,1.614,2.816),Vector3(.30,.12,.036),black,.037)
	box(gate,Vector3(0,1.640,2.84),Vector3(.22,.040,.027),black,.010)
	# Sculpted steel bumper, hitch and recovery rings.
	box(shell,Vector3(0,.925,2.80),Vector3(1.09,.29,.32),black,.055)
	for side in [-1,1]:
		box(shell,Vector3(side*.885,.96,2.77),Vector3(.78,.31,.33),materials["Textured graphite"],.06,Vector3(0,side*.075,side*.055),steel_patch)
		box(shell,Vector3(side*.59,.842,2.963),Vector3(.15,.18,.09),black,.025)
		ring(shell,Vector3(side*.59,.754,3.021),.073,.019,bolts,0,20,8)
		box(shell,Vector3(side*.995,1.01,2.985),Vector3(.143,.109,.021),materials["White lamps"],.016)
		box(shell,Vector3(side*1.112,1.454,2.799),Vector3(.178,.545,.091),black,.048)
		for y in [1.30,1.59]:
			box(shell,Vector3(side*1.112,y,2.852),Vector3(.141,.208,.035),materials["Brake lamps"],.037)
			for x in range(5):
				for row in range(7):
					box(shell,Vector3(side*1.112+(x-2)*.021,y+(row-3)*.020,2.876),Vector3(.010,.010,.006),materials["Amber beacons"],.002)
		box(shell,Vector3(side*1.112,1.446,2.86),Vector3(.132,.057,.035),materials["White lamps"],.010)
	box(shell,Vector3(0,.762,2.978),Vector3(.16,.16,.115),bolts,.021)
	box(shell,Vector3(0,.762,3.04),Vector3(.103,.103,.011),black,.009)
	# Bed frame; cage diagonals match the familiar rear silhouette.
	for side in [-1,1]:
		tube(shell,Vector3(side*1.03,1.78,2.35),Vector3(side*.925,2.33,.90),.062,black)
		tube(shell,Vector3(side*.925,2.33,.90),Vector3(side*.83,2.41,.70),.062,black)
		tube(shell,Vector3(side*.975,1.75,.97),Vector3(side*.28,2.33,.91),.047,black)
		tube(shell,Vector3(side*1.018,1.83,2.47),Vector3(side*1.018,1.83,.91),.045,black)
		tube(shell,Vector3(side*.86,2.44,-.51),Vector3(side*.86,2.44,.69),.042,black)
		for z in [-.47,.65]:tube(shell,Vector3(side*.85,2.35,z),Vector3(side*.85,2.46,z),.036,black)
		tube(shell,Vector3(side*.925,2.33,.90),Vector3(0,2.33,.90),.061,black)
	for z in [-.50,.08,.69]:tube(shell,Vector3(-.86,2.44,z),Vector3(.86,2.44,z),.041,black)
	box(shell,Vector3(0,2.385,.85),Vector3(.44,.061,.038),materials["Brake lamps"],.018)
	# Mesh protection on the back window: small wires in physical depth.
	for i in range(17):
		var x: float=-.80+i*.10
		tube(shell,Vector3(x,1.81,.923),Vector3(x,2.255,.794),.0055,black,-1,6)
	for i in range(6):
		var y: float=1.82+i*.08
		tube(shell,Vector3(-.82,y,.925-(y-1.81)*.296),Vector3(.82,y,.925-(y-1.81)*.296),.0055,black,-1,6)
	# Rugged cases, straps and latches, leaving the right rear berth for Mateo.
	for spec in [[Vector3(-.53,1.39,1.41),Vector3(.83,.46,.67),"Equipment black"],[Vector3(.32,1.43,1.11),Vector3(.38,.59,.44),"Equipment olive"],[Vector3(-.61,1.31,2.19),Vector3(.58,.30,.48),"Equipment black"]]:
		var p: Vector3=spec[0];var sz: Vector3=spec[1];var mat: Material=materials[spec[2]]
		box(shell,p,sz,mat,.066)
		box(shell,p+Vector3(0,sz.y*.29,0),Vector3(sz.x+.025,.034,sz.z+.020),black,.015)
		for side in [-1,1]:
			box(shell,p+Vector3(side*sz.x*.32,0,0),Vector3(.049,sz.y+.017,sz.z+.018),materials["Canvas straps"],.010)
			box(shell,p+Vector3(side*sz.x*.32,-.018,sz.z*.5+.023),Vector3(.062,.108,.023),bolts,.009)
		box(shell,p+Vector3(0,sz.y*.5+.023,0),Vector3(sz.x*.31,.046,.097),black,.014)
	# Roof electronics and unmistakable twin orange beacons.
	box(shell,Vector3(0,2.59,.31),Vector3(.74,.19,.37),materials["Equipment black"],.040)
	for side in [-1,1]:
		box(shell,Vector3(side*.71,2.537,.14),Vector3(.28,.069,.25),black,.022)
		tube(shell,Vector3(side*.71,2.57,.14),Vector3(side*.71,2.735,.14),.112,materials["Amber beacons"],.080,24)
		for i in range(12):
			var a: float=i*TAU/12
			tube(shell,Vector3(side*.71+sin(a)*.10,2.58,.14+cos(a)*.10),Vector3(side*.71+sin(a)*.072,2.725,.14+cos(a)*.072),.006,materials["White lamps"],-1,6)
	# Actual concave dish, tilted slightly rearward.
	var dish:=group("RadarDish",shell,Vector3(0,2.97,-.42))
	dish.rotation.x=.12
	tube(shell,Vector3(0,2.48,-.42),Vector3(0,2.985,-.42),.09,black,.075,20)
	for y in [2.64,2.77,2.90]:tube(shell,Vector3(0,y,-.42),Vector3(0,y+.025,-.42),.139,bolts,-1,20)
	var dish_st:=surface(dish,materials["Dish aluminum"])
	for i in range(48):
		for j in range(8):
			var ps: Array[Vector3]=[];var ns: Array[Vector3]=[]
			for ij in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
				var a: float=(i+ij.x)*TAU/48;var r: float=(j+ij.y)*.62/8
				ps.append(Vector3(sin(a)*r,.29*r*r/(.62*.62),cos(a)*r))
				ns.append(Vector3(-sin(a)*r*.58/(.62*.62),1,-cos(a)*r*.58/(.62*.62)).normalized())
			tri(dish_st,ps[0],ps[1],ps[2],ns[0],ns[1],ns[2]);tri(dish_st,ps[0],ps[2],ps[3],ns[0],ns[2],ns[3])
			tri(dish_st,ps[0]-Vector3.UP*.016,ps[1]-Vector3.UP*.016,ps[2]-Vector3.UP*.016,-ns[0],-ns[1],-ns[2])
			tri(dish_st,ps[0]-Vector3.UP*.016,ps[2]-Vector3.UP*.016,ps[3]-Vector3.UP*.016,-ns[0],-ns[2],-ns[3])
	ring(dish,Vector3(0,.29,0),.62,.013,bolts,1,48,6)
	# Four antennas, separate flex pivots; the mast itself never stretches.
	for side in [-1,1]:
		for rear in [true,false]:
			var ant:=group(("Rear" if rear else "Roof")+("LeftAntenna" if side<0 else "RightAntenna"),shell,Vector3(side*(1.025 if rear else .87),1.85 if rear else 2.51,2.41 if rear else .57))
			var length:=2.06 if rear else 1.05
			tube(ant,Vector3.ZERO,Vector3(0,.21,0),.060,black,.037,14)
			for i in range(10):
				tube(ant,Vector3(0,.09+i*.016,0),Vector3(0,.096+i*.016,0),.044,bolts,-1,12)
			tube(ant,Vector3(0,.20,0),Vector3(0,length,0),.017,black,.008,10)
			tube(ant,Vector3(0,length,0),Vector3(0,length+.029,0),.014,black,-1,10)
	for side in [-1,1]:
		build_wheel("FrontLeftWheel" if side<0 else "FrontRightWheel",Vector3(side*1.225,.67,-1.77))
		build_wheel("RearLeftWheel" if side<0 else "RearRightWheel",Vector3(side*1.225,.67,1.77))
	group("MateoSeat",shell,Vector3(.53,1.20,2.01))
	for key in batches:
		var b: Dictionary=batches[key]
		var st: SurfaceTool=b.surface
		st.index();st.generate_tangents()
		var instance:=MeshInstance3D.new()
		instance.name=b.material.resource_name.validate_node_name()
		instance.mesh=st.commit();instance.mesh.surface_set_material(0,b.material)
		b.parent.add_child(instance)
	_assign_owner(vehicle)
	var packed:=PackedScene.new();packed.pack(vehicle)
	ResourceSaver.save(packed,"res://assets/models/interceptor-3d.tscn")
	var doc:=GLTFDocument.new();var state:=GLTFState.new()
	var result:=doc.append_from_scene(vehicle,state)
	if result==OK:result=doc.write_to_filesystem(state,"res://assets/models/interceptor-3d.glb")
	print("INTERCEPTOR_3D_BUILD ",JSON.stringify({"triangles":total_triangles,"material_batches":batches.size(),"glb_export":result,"source_art":"truck.png","wheel_radius_m":.655,"wheelbase_m":3.54}))
	vehicle.queue_free();await process_frame
	quit(0 if result==OK else 1)

func _assign_owner(n: Node) -> void:
	for child in n.get_children():
		child.owner=vehicle;_assign_owner(child)
