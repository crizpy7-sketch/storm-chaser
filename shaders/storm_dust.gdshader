shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
uniform float clock=0.0;
uniform float seed=0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 vec2 p=UV*2.0-1.0;
 float grain=noise(UV*5.0+vec2(clock*.25+seed,-clock*.2));
 float shape=1.0-smoothstep(.25,1.0,length(p)+grain*.18);
 ALBEDO=mix(vec3(.17,.14,.11),vec3(.36,.29,.20),grain);
 ALPHA=shape*(.22+grain*.22);
}
