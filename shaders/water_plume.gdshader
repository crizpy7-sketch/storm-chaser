shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float age = 0.0;
uniform float opacity = 0.3;
uniform float seed = 0.0;
uniform float sheet = 0.0;
uniform float dust = 0.0;
float n(vec2 p) {return sin(p.x*9.3+sin(p.y*6.7))*sin(p.y*8.1+sin(p.x*5.1))*0.5+0.5;}
void fragment(){
 vec2 p=UV*2.0-1.0;
 float shape=1.0-smoothstep(0.15,1.0,length(p*vec2(0.95,1.0)));
 float cloud=n(p*1.8+vec2(seed,age*0.9));
 float fine=n(p*7.0+seed-age);
 float streak=pow(max(0.0,sin((p.x+p.y*0.28)*38.0+fine*3.0)),5.0);
 float body=mix(0.55+cloud*0.45,0.38+cloud*0.45+streak*0.23,sheet);
 ALBEDO=mix(vec3(0.29,0.42,0.45),vec3(0.68,0.81,0.83),cloud*0.7+fine*0.3);
 ALBEDO=mix(ALBEDO,mix(vec3(.36,.20,.085),vec3(.70,.46,.235),cloud*.7+fine*.3),dust);
 ALPHA=shape*opacity*body*(1.0+dust*.5);
}
