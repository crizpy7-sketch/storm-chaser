extends Node3D
# Small, bounded fragments share the real contact position and scene pause state.
var game
var world
var pieces: Array[Dictionary]=[]
var cursor:=0
var last_origin:=Vector3.ZERO
var bursts:=0
func build() -> void:
	var metal: Material=world.material(Color("b4b7a6"),.60,.48)
	var wood: Material=world.material(Color("8a704c"),0,.92)
	for i in range(48):
		var node: MeshInstance3D=world.box(self,Vector3.ZERO,Vector3(.06,.05,.16+(i%4)*.07),wood if i%3==0 else metal)
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.hide()
		pieces.append({"node":node,"age":2.0,"velocity":Vector3.ZERO,"spin":Vector3.ZERO})
func burst(point: Vector3, normal: Vector3, _theme: int, _kind: int) -> void:
	last_origin=point;bursts+=1
	for i in range(8 if game.calm_fx or game.light_graphics else 20):
		var p: Dictionary=pieces[cursor];cursor=(cursor+1)%pieces.size()
		var a:=i*2.399+bursts*.7
		p.node.position=point+normal*.04;p.node.rotation=Vector3(a,a*.7,0);p.node.show();p.age=0.0
		p.velocity=normal*(5.0+fmod(i*1.7,4.0))+Vector3(sin(a)*3.0,2.0+fmod(i*.9,3.0),cos(a)*2.0)
		p.spin=Vector3(sin(a),cos(a),.8)*9.0
func step(dt: float) -> void:
	for p in pieces:
		if not p.node.visible:continue
		p.age+=dt
		if p.age>.55:p.node.hide();continue
		p.node.position+=p.velocity*dt;p.velocity.y-=13.0*dt;p.node.rotation+=p.spin*dt
func reset() -> void:
	cursor=0;bursts=0;last_origin=Vector3.ZERO
	for p in pieces:p.age=2.0;p.node.hide()
