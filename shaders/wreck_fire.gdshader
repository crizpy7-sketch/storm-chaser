shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float clock = 0.0;
uniform float seed = 0.0;
uniform float strength = 1.0;
uniform float calm = 0.0;
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise2(vec2 p) {
 vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p) { return noise2(p)*.57+noise2(p*2.03)*.28+noise2(p*4.11)*.15; }
void fragment() {
 float y=1.0-UV.y;
 float t=clock*(1.0-calm*.45)+seed;
 float x=UV.x-.5-y*.16;
 float smoke=fbm(vec2(x*7.0,y*6.0-t*.32));
 float edge=1.0-smoothstep(.12,.37,abs(x+sin(y*11.0-t*.4)*.045));
 float haze=edge*smoothstep(.13,.35,y)*(1.0-smoothstep(.70,1.0,y))*smoothstep(.23,.64,smoke)*.93;
 float flicker=fbm(vec2(x*23.0,y*18.0-t*2.6));
 float flame=0.0;
 for(int i=0;i<3;i++) {
  float k=float(i);
  float h=.19+k*.04+.045*sin(t*2.4+k*2.1);
  float center=(k-1.0)*.086+sin(y*19.0-t*2.0+k*3.1)*y*.20;
  float width=max(.004,.083*(1.0-y/h))*(.65+flicker*.75);
  float strand=(1.0-smoothstep(width*.35,width,abs(x-center)))*(1.0-smoothstep(h*.68,h,y));
  flame=max(flame,strand);
 }
 flame*=smoothstep(.22,.62,flicker+.22)*smoothstep(0.0,.025,y)*strength;
 float core=clamp((1.0-y/.20)*flame,0.0,1.0);
 vec3 fire=mix(vec3(.82,.19,.028),vec3(1.0,.76,.32),core);
 vec3 soot=mix(vec3(.12,.14,.14),vec3(.30,.31,.29),smoke);
 ALBEDO=mix(soot,fire,flame);
 EMISSION=fire*flame*(1.4+core*.9);
 ALPHA=max(haze*strength,flame*.94);
}
