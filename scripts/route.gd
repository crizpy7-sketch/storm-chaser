extends RefCounted

# One course supplies road vertices, hazard positions, ground contact and turns.
const STEP := 3.0
const ORBIT_RADIUS := 92.0
const ORBIT_APPROACH := 140.0
const GRAVITY := 23.0
const SHORTCUT_TURN_START := 140.0
const SHORTCUT_RADIUS := 14.0
const SHORTCUT_TURN_END := SHORTCUT_TURN_START + SHORTCUT_RADIUS * PI * 0.5
const SHORTCUT_JUNCTION_Z := SHORTCUT_TURN_START + SHORTCUT_RADIUS
var game
var level := 0
var progress := 0.0
var paths: Dictionary = {}
var active := false
var curvature := 0.0
var drift := 0.0
var traction := 1.0
var dirt := 0.0
var grounded := true
var body_y := 0.0
var vertical_velocity := 0.0
var ground_velocity := 0.0
## Vertical acceleration of the surface under the wheels. The ramp face pushes
## up hard and the crest pulls down; truck_rig loads the springs against it.
var ground_acceleration := 0.0
var air_height := 0.0
var air_time := 0.0
var pitch := 0.0
var landing := 0.0
var landing_severity := 0.0
var launches := 0
var landings := 0
var hard_landings := 0
var launch_cooldown := 0.0
var edge_time := 0.0
var hint := ""
var upcoming_curve := 0.0
var upcoming_grade := 0.0
var shortcut_slide := 0.0
var shortcut_entry_played := false
var shortcut_mud_played := false
# The truck's current course frame. Every visible road/terrain vertex is
# projected through it, so it is computed once per progress value.
var _frame_level := -1
var _frame_progress := INF
var _frame_origin := Vector2.ZERO
var _frame_cos := 1.0
var _frame_sin := 0.0
var _frame_height := 0.0

func enter(next_level: int) -> void:
	level=next_level;active=level>=3;progress=0.0
	curvature=0.0;drift=0.0;traction=1.0;dirt=0.0
	grounded=true;body_y=0.0;vertical_velocity=0.0;ground_velocity=0.0;ground_acceleration=0.0
	air_height=0.0;air_time=0.0;pitch=0.0;landing=0.0;landing_severity=0.0
	launches=0;landings=0;hard_landings=0;launch_cooldown=0.0;edge_time=0.0;hint=""
	shortcut_slide=0.0;shortcut_entry_played=false;shortcut_mud_played=false
	if active and not paths.has(level):
		var origin:=Vector2(SHORTCUT_RADIUS+260.0-SHORTCUT_TURN_END,-SHORTCUT_JUNCTION_Z) if level==4 else Vector2.ZERO
		var points:=PackedVector2Array([origin])
		for i in range(1100):
			var a:=heading((260.0 if level==4 else 0.0)+(i+0.5)*STEP)
			points.append(points[-1]+Vector2(sin(a),-cos(a))*STEP)
		paths[level]=points
	dirt=dirt_at(0.0)
	body_y=height_at(0.0)

func heading(s: float) -> float:
	var q:=maxf(s,0.0)
	if level==3:
		return (sin(q*TAU/520.0)*0.53+sin(q*TAU/260.0)*0.08)*smoothstep(0.0,65.0,q)
	if level==4:
		return clampf((q-SHORTCUT_TURN_START)/SHORTCUT_RADIUS,0.0,PI*0.5)+sin(maxf(q-260.0,0.0)*TAU/440.0)*0.14*smoothstep(260.0,340.0,q)
	if level==5:return sin(q*TAU/620.0)*0.14
	if level==6:return (sin(q*TAU/455.0)*0.53+sin(q*TAU/235.0)*0.09)*smoothstep(0.0,70.0,q)
	if level==7:return maxf(0.0,q-ORBIT_APPROACH)/ORBIT_RADIUS
	return 0.0

func course(s: float) -> Vector2:
	if s<=0.0:return Vector2(0,-s)
	if level==4 and s<=260.0:
		if s<=SHORTCUT_TURN_START:return Vector2(0,-s)
		if s<SHORTCUT_TURN_END:
			var a:=(s-SHORTCUT_TURN_START)/SHORTCUT_RADIUS
			return Vector2(SHORTCUT_RADIUS*(1.0-cos(a)),-SHORTCUT_TURN_START-SHORTCUT_RADIUS*sin(a))
		return Vector2(SHORTCUT_RADIUS+s-SHORTCUT_TURN_END,-SHORTCUT_JUNCTION_Z)
	if level==7:
		if s<=ORBIT_APPROACH:return Vector2(0,-s)
		var a:=(s-ORBIT_APPROACH)/ORBIT_RADIUS
		return Vector2(ORBIT_RADIUS*(1.0-cos(a)),-ORBIT_APPROACH-ORBIT_RADIUS*sin(a))
	var points: PackedVector2Array=paths.get(level,PackedVector2Array([Vector2.ZERO]))
	var sample_s:=s-(260.0 if level==4 else 0.0)
	var index:=clampi(floori(sample_s/STEP),0,points.size()-2)
	return points[index].lerp(points[index+1],clampf(sample_s/STEP-index,0,1))

func _frame() -> void:
	if _frame_progress==progress and _frame_level==level:return
	_frame_progress=progress;_frame_level=level
	_frame_origin=course(progress)
	var a:=heading(progress)
	_frame_cos=cos(a);_frame_sin=sin(a)
	_frame_height=height_at(progress)

func project(point: Vector2) -> Vector2:
	_frame()
	var dx:=point.x-_frame_origin.x
	var dy:=point.y-_frame_origin.y
	return Vector2(dx*_frame_cos+dy*_frame_sin,-dx*_frame_sin+dy*_frame_cos)

func point(z: float, lateral: float = 0.0) -> Vector3:
	if not active:return Vector3(lateral,0,z)
	_frame()
	var s:=progress-z
	var a:=heading(s)
	var c:=course(s)
	var dx:=c.x+cos(a)*lateral-_frame_origin.x
	var dy:=c.y+sin(a)*lateral-_frame_origin.y
	return Vector3(dx*_frame_cos+dy*_frame_sin,height_at(s)-_frame_height,-dx*_frame_sin+dy*_frame_cos)

## Projects a fixed course-space point with its ground height into the truck frame,
## exactly as point() does for the same course position.
func project_point(canonical: Vector2, height: float) -> Vector3:
	_frame()
	var dx:=canonical.x-_frame_origin.x
	var dy:=canonical.y-_frame_origin.y
	return Vector3(dx*_frame_cos+dy*_frame_sin,height-_frame_height,-dx*_frame_sin+dy*_frame_cos)

## Road row at z: [center point, unit lateral direction]. Every lateral point of a
## row is center + right * lateral, exactly as point(z, lateral) computes it.
func row(z: float) -> Array:
	_frame()
	var s:=progress-z
	var a:=heading(s)
	var c:=course(s)
	var dx:=c.x-_frame_origin.x
	var dy:=c.y-_frame_origin.y
	var center:=Vector3(dx*_frame_cos+dy*_frame_sin,height_at(s)-_frame_height,-dx*_frame_sin+dy*_frame_cos)
	var ca:=cos(a);var sa:=sin(a)
	return [center,Vector3(ca*_frame_cos+sa*_frame_sin,0.0,-ca*_frame_sin+sa*_frame_cos)]

func grade(s: float) -> float:
	return (height_at(s+0.7)-height_at(s-0.7))/1.4

func rotation_at(z: float) -> Vector3:
	return Vector3(atan(grade(progress-z)),-(heading(progress-z)-heading(progress)),0)

func bump(s: float, spacing: float, amplitude: float, width: float, offset: float) -> float:
	var q:=s-offset
	if q<0:return 0.0
	var u:=fposmod(q,spacing)/width
	if u>=1:return 0.0
	return amplitude*pow(sin(u*PI),2.0)

func height_at(s: float) -> float:
	if level==4:return bump(s,158.0,1.5,120.0,300.0)
	if level==5:return bump(s,198.0,10.0,80.0,92.0)
	if level==6:return bump(s,185.0,12.0,82.0,95.0)
	return 0.0

func dirt_at(s: float) -> float:
	if level<4:return 0.0
	# Mud starts at the right edge of the straight highway, not along its lane.
	if level==4:return smoothstep(6.8,7.3,course(s).x)
	return 1.0

func width(z: float = 0.0) -> float:
	return lerpf(14.0,11.0,dirt_at(progress-z))

func lane_scale(z: float = 0.0) -> float:
	return width(z)*(5.8/14.0)

func orbit_progress() -> float:
	return clampf((progress-ORBIT_APPROACH)/(TAU*ORBIT_RADIUS),0,1) if level==7 else 0.0

func tornado_point() -> Vector3:
	var p:=project(Vector2(ORBIT_RADIUS,-ORBIT_APPROACH))
	return Vector3(p.x,0,p.y)

func step(dt: float) -> void:
	if not active or dt<=0:return
	# Jumps integrate ground slope and gravity; fixed small substeps keep launch
	# points, flight height and landings the same at 30, 60 or 144 FPS.
	var remaining:=dt
	while remaining>0.000001:
		var h:=minf(remaining,1.0/120.0)
		remaining-=h
		_step(h)

func _step(dt: float) -> void:
	var v: float=game.speed*0.25
	var old_ground:=height_at(progress)
	progress+=v*dt
	var new_ground:=height_at(progress)
	var next_ground_velocity: float=(new_ground-old_ground)/dt
	ground_acceleration=(next_ground_velocity-ground_velocity)/dt
	dirt=dirt_at(progress)
	curvature=(heading(progress+1.0)-heading(progress-1.0))*0.5
	upcoming_curve=(heading(progress+45.0)-heading(progress))/45.0
	upcoming_grade=grade(progress+38.0)
	var slide_target := 0.0
	if level==4 and progress>SHORTCUT_TURN_START and progress<SHORTCUT_TURN_END+45.0 and grounded:
		slide_target=smoothstep(0.005,0.020,absf(curvature))*smoothstep(62.0,110.0,game.speed)
		if progress>SHORTCUT_TURN_END and shortcut_entry_played:
			slide_target=(1.0-smoothstep(SHORTCUT_TURN_END+8.0,SHORTCUT_TURN_END+42.0,progress))*smoothstep(62.0,110.0,game.speed)
	shortcut_slide=lerpf(shortcut_slide,slide_target,1.0-exp(-dt*(4.5 if slide_target>shortcut_slide else 2.5)))
	if shortcut_slide>0.42 and not shortcut_entry_played:
		shortcut_entry_played=true
		game.notify("90° RIGHT  /  CATCH THE REAR",2.2)
	if level==4 and dirt>0.5 and grounded and not shortcut_mud_played:
		shortcut_mud_played=true
		game.play_sound("splash")
		game.haptic(95,0.75)
		game.world.water_fx.drift_burst()
		game.splash_pulse=1.0
	landing=maxf(0,landing-dt*0.85*game.setup_factor("landing"))
	launch_cooldown=maxf(0,launch_cooldown-dt)
	traction=lerpf(1.0,minf(1.0,(0.67 if level==4 else 0.56)*game.setup_factor("dirt_grip")),dirt)
	traction*=lerpf(1.0,0.78,shortcut_slide)
	if not grounded:traction*=0.28
	traction*=lerpf(1.0,0.53,landing)
	var tire_help: float=lerpf(0.48,1.0,sqrt(game.tires))
	var force: float=-curvature*v*v/5.8*tire_help
	if game.steering_assist:force*=0.7
	drift+=force*dt
	var recovery: float=lerpf(1.85 if dirt>0.5 else 2.3,1.3,shortcut_slide)
	drift*=exp(-dt*recovery*(1.6 if game.braking else 1.0))
	# The shoulder must remain recoverable with full steering during the hairpin.
	var limit := 1.8 if level==4 else 2.2
	drift=clampf(drift,-limit,limit)
	if grounded:
		body_y=new_ground
		if level in [5,6] and launch_cooldown==0 and game.speed>100 and ground_acceleration < -GRAVITY*1.08 and ground_velocity>1.6:
			grounded=false;vertical_velocity=ground_velocity;body_y=old_ground+vertical_velocity*dt
			air_time=0.0;launches+=1
			game.notify("AIRBORNE  /  STRAIGHTEN BEFORE LANDING",1.7)
	else:
		air_time+=dt
		vertical_velocity-=GRAVITY*dt
		body_y+=vertical_velocity*dt
		if body_y<=new_ground:
			var impact:=maxf(0.0,next_ground_velocity-vertical_velocity)
			_land(impact)
			body_y=new_ground;grounded=true;vertical_velocity=0;launch_cooldown=0.9
	ground_velocity=next_ground_velocity
	air_height=maxf(0.0,body_y-new_ground)
	var target_pitch: float=clampf(atan(grade(progress)), -0.10,0.10) if grounded else clampf(vertical_velocity*0.0135,-0.21,0.17)
	pitch=lerpf(pitch,target_pitch,1-exp(-dt*5.5))
	if absf(game.player_x)>1.03:
		edge_time+=dt
		if edge_time>0.65:
			game.health=maxf(0,game.health-dt*(7.0 if level==3 else 9.0)*game.setup_factor("damage"))
			game.notify("SHOULDER  /  BRAKE AND STEER BACK",1.2)
	else:edge_time=0.0
	if not grounded:hint="AIRBORNE  /  LINE UP YOUR LANDING"
	elif landing>0.25:hint="LANDING SLIDE  /  COUNTERSTEER"
	elif shortcut_slide>0.25:hint="RIGHT-HAND DRIFT  /  CATCH THE REAR"
	elif level==4 and progress<140:hint="SHARP RIGHT  /  TAP BRAKE, THEN TURN"
	elif absf(upcoming_curve)>0.004:hint=("RIGHT BEND" if upcoming_curve>0 else "LEFT BEND")+"  /  EASE OFF BOOST"
	elif level in [5,6] and upcoming_grade>0.10:hint="BIG CREST  /  BRAKE TO STAY GROUNDED"
	elif level==7:hint="CIRCLE THE VORTEX  /  FIGHT THE CROSSWIND"
	else:hint="LOOSE SURFACE  /  SMOOTH STEERING" if dirt>0.5 else "FOLLOW THE CURVE"

func _land(impact: float) -> void:
	landings+=1
	landing=1.0
	# impact 18 still maps to exactly 1.0 (the reference landing the harness
	# asserts against); the headroom above it is what separates a hop from a
	# 23-metre crest landing. Measured impacts run 6.4 to 32.8.
	landing_severity=clampf(impact/18.0,0.15,1.6)
	var side: float=clampf(game.velocity_x+game.glide_velocity+drift,-2,2)
	var kick: float=side*landing_severity*(0.85 if game.steering_assist else 1.55)
	game.glide_velocity=clampf(game.glide_velocity+kick,-2.2,2.2)
	game.aquaplane=maxf(game.aquaplane,minf(0.92,0.25+landing_severity*0.48))
	game.rear_slip_velocity+=clampf(kick,-1.5,1.5)
	game.speed=maxf(60,game.speed-landing_severity*11.0)
	game.shake=maxf(game.shake,landing_severity*5.5)
	game.haptic(int(70+landing_severity*70),clampf(landing_severity,0.0,1.0)*0.85)
	# Audio weight reads the raw impact, so the hardest landings stay separable
	# even though landing_severity is bounded for the handling model.
	var heard: float=clampf(impact/26.0,0.15,1.0)
	game.landing_audio.pitch_scale=lerpf(1.15,0.66,heard)
	game.landing_audio.volume_db=lerpf(-18.0,-4.0,heard)
	game.landing_audio.play()
	if absf(side)>0.95 and impact>9.0:
		hard_landings+=1
		game.health=maxf(0,game.health-minf(12.0,(impact-7.0)*0.65)*game.setup_factor("damage"))
		game.notify("HARD LANDING  /  CATCH THE SLIDE",1.8)
	else:
		game.score+=200+minf(air_time*100.0,250.0)
		game.notify("LANDING HELD  /  +%d DATA" % int(200+minf(air_time*100.0,250.0)),1.6)

func brake_advised() -> bool:
	return (level==4 and progress>104 and progress<139) or (absf(upcoming_curve)>0.006 and game.speed>132) or (level in [5,6] and upcoming_grade>0.20 and game.speed>158)

func chapter_caption() -> String:
	return {
		3:"Brake into bends. Fight the outward drift.",
		4:"Sharp right. Take the dirt shortcut into rolling hills.",
		5:"Big crests. Get airborne and catch the landing.",
		6:"Tight curves and big jumps. Keep your landing straight.",
		7:"Circle the tornado. Record the final approach."
	}.get(level,"")
