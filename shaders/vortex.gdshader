shader_type canvas_item;
uniform float clock=0.0;
void fragment(){
 vec2 uv=UV;
 float sway=sin(uv.y*11.0-clock*2.1)*0.012+sin(uv.y*23.0+clock*1.6)*0.004;
 uv.x+=sway*sin(uv.y*3.14159);
 vec4 col=texture(TEXTURE,uv);
 float rolling=0.96+0.04*sin(uv.y*45.0-clock*7.0+uv.x*8.0);
 COLOR=vec4(col.rgb*rolling,col.a)*COLOR;
}
