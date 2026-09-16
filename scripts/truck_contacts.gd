extends RefCounted
# Swept separating-axis contacts using the same transforms/bounds as the renderer.
# Sweeping the entire frame prevents high-speed objects skipping through the cab.
var game
var previous_truck := Transform3D.IDENTITY
var has_previous := false
const HULLS = [
	AABB(Vector3(-1.15,.52,-2.94),Vector3(2.30,1.17,5.84)),
	AABB(Vector3(-.99,1.69,-1.15),Vector3(1.98,.70,2.12)),
	AABB(Vector3(-1.04,1.69,1.0),Vector3(2.08,.35,1.81)),
	AABB(Vector3(-1.42,.05,-2.39),Vector3(.55,1.23,1.31)),
	AABB(Vector3(.87,.05,-2.39),Vector3(.55,1.23,1.31)),
	AABB(Vector3(-1.42,.05,1.15),Vector3(.55,1.23,1.31)),
	AABB(Vector3(.87,.05,1.15),Vector3(.55,1.23,1.31))
]
func truck_transform() -> Transform3D:
	return Transform3D(Basis.from_euler(Vector3(game.route.pitch,game.world.scene_truck_yaw(),0)),game.world.road_point(0,game.player_x)+Vector3.UP*(.025+game.route.air_height))
func begin_step() -> void:
	previous_truck=truck_transform();has_previous=true
func reset() -> void:
	has_previous=false
func sweep(before: Transform3D, after: Transform3D, bounds: AABB) -> Dictionary:
	var truck:=truck_transform()
	var old:=previous_truck if has_previous else truck
	var a:=old.affine_inverse()*before
	var b:=truck.affine_inverse()*after
	var best: Dictionary={}
	for hull in HULLS:
		var hit:=_sweep_box(hull,bounds,a,b)
		if not hit.is_empty() and (best.is_empty() or hit.t<best.t):best=hit
	if best.is_empty():return best
	best.point=truck*best.point
	best.normal=(truck.basis*best.normal).normalized()
	best.transform=before.interpolate_with(after,best.t)
	return best

static func _radius(basis: Basis, half: Vector3, axis: Vector3) -> float:
	return absf(axis.dot(basis.x))*half.x+absf(axis.dot(basis.y))*half.y+absf(axis.dot(basis.z))*half.z

static func _sweep_box(hull: AABB, bounds: AABB, a: Transform3D, b: Transform3D) -> Dictionary:
	var center:=hull.get_center();var half:=hull.size*.5;var obj_half:=bounds.size*.5
	var p:=a*bounds.get_center()-center
	var end:=b*bounds.get_center()-center
	var delta:=end-p
	var axes: Array[Vector3]=[Vector3.RIGHT,Vector3.UP,Vector3.BACK,b.basis.x.normalized(),b.basis.y.normalized(),b.basis.z.normalized()]
	for i in range(3):
		for j in range(3):
			var axis:=axes[i].cross(axes[3+j])
			if axis.length_squared()>.000001:axes.append(axis.normalized())
	var enter:=0.0;var leave:=1.0;var normal:=Vector3.FORWARD
	var depth:=INF
	for axis in axes:
		var radius:=half.dot(axis.abs())+maxf(_radius(a.basis,obj_half,axis),_radius(b.basis,obj_half,axis))+.004
		var start:=p.dot(axis);var speed:=delta.dot(axis)
		if radius-absf(start)<depth:
			depth=radius-absf(start);normal=axis*signf(start) if enter==0.0 else normal
		if absf(speed)<.000001:
			if absf(start)>radius:return {}
			continue
		var first:=(-radius-start)/speed;var last:=(radius-start)/speed
		if first>last:
			var swap:=first;first=last;last=swap
		if first>enter:
			enter=first;normal=-axis if speed>0 else axis
		leave=minf(leave,last)
		if enter>leave:return {}
	if leave<0.0 or enter>1.0:return {}
	if normal.length_squared()<.5:normal=Vector3.FORWARD
	var object_center: Vector3=(a*bounds.get_center()).lerp(b*bounds.get_center(),enter)
	var contact:=object_center-normal*_radius(b.basis,obj_half,normal)
	contact=contact.clamp(hull.position,hull.end)
	return {"t":enter,"point":contact,"normal":normal}
