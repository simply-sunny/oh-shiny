// The game's clouds, lit by the sun, moon and sky like everything else (see clouds.fsh).

#include "/lib/frame.glsl"

out vec4 v_Color;
out vec3 v_Position;

void main() {
    mx_setup();
    v_Color = gl_Color;
    vec3 view = (gl_ModelViewMatrix * gl_Vertex).xyz;
    v_Position = mat3(gbufferModelViewInverse) * view;
    gl_Position = gl_ProjectionMatrix * vec4(view, 1.0);
}
