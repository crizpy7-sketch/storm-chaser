shader_type canvas_item;
render_mode unshaded;
uniform float amount=0.0;
uniform float clock=0.0;
void fragment(){
 vec2 uv=UV;
 float edge=smoothstep(0.17,0.5,abs(uv.x-0.5));
 float haze=(0.5+0.5*sin(uv.y*13.0+uv.x*9.0))*edge;
 vec2 grid=vec2(uv.x*18.0,uv.y*11.0-clock*0.22);
 vec2 cell=fract(grid)-0.5;
 vec2 id=floor(grid);
 float random=fract(sin(dot(id,vec2(127.1,311.7)))*43758.5453);
 float droplet=(1.0-smoothstep(0.08,0.14,length(cell*vec2(1.2,0.72))))*step(0.64,random);
 float rim=(1.0-smoothstep(0.013,0.04,abs(length(cell*vec2(1.2,0.72))-0.13)))*step(0.64,random);
 COLOR=vec4(0.61,0.76,0.80,amount*edge*(haze*0.09+droplet*0.12+rim*0.20));
}
