shader_type canvas_item;
uniform float travel = 0.0;
uniform float bend = 0.0;
uniform float brightness = 1.0;
uniform float stage = 0.0;
uniform float horizon = 0.46944;
uniform float camera_x = 0.0;
uniform float rush = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
 float h = horizon;
 float q = clamp((UV.y-h)/(1.0-h),0.0,1.0);
 float cx = 0.5 + camera_x + bend*0.109375*pow(1.0-q,2.0);
 float hw = 0.015 + q*0.46;
 float x=(UV.x-cx)/hw;
 float z=5.0/(q+0.035)+travel;
 float grit=noise(vec2(x*100.0,z*mix(13.0,5.0,rush)));
 float broad=noise(vec2(x*7.0,z*0.6));
 vec3 field=mix(vec3(0.10,0.13,0.105),vec3(0.23,0.22,0.135),grit*0.35+broad*0.4);
 field*=0.84+0.16*noise(vec2(x*4.0,z*0.35));
 field=mix(field,vec3(0.13,0.14,0.11),stage*0.05);
 vec3 road=mix(vec3(0.027,0.045,0.055),vec3(0.12,0.16,0.17),grit*0.50+broad*0.15);
 float wet=noise(vec2(x*22.0,z*0.75));
 road+=vec3(0.11,0.16,0.18)*pow(wet,5.0)*0.8;
 road+=vec3(0.22,0.14,0.06)*pow(max(0.0,1.0-abs(x-0.57)*2.0),4.0)*wet*0.25;
 float stripe=step(0.025,abs(x))*step(abs(x),0.043);
 road=mix(road,vec3(0.65,0.49,0.19),stripe*0.9);
 float edge=step(0.92,abs(x))*step(abs(x),0.935);
 road=mix(road,vec3(0.60,0.64,0.59),edge*0.75);
 float dashed=step(abs(abs(x)-0.47),0.010)*step(0.47,fract(z*0.12));
 road=mix(road,vec3(0.52,0.59,0.57),dashed*0.68);
 vec3 col=mix(field,road,1.0-smoothstep(0.985,1.02,abs(x)));
 float shoulder=step(1.01,abs(x))*step(abs(x),1.045);
 col=mix(col,vec3(0.26,0.25,0.20),shoulder*0.5);
 col=mix(vec3(0.20,0.25,0.25),col,smoothstep(0.0,0.23,q));
 col*=brightness;
 COLOR=vec4(col,step(h,UV.y));
}
