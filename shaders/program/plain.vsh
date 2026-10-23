// What keeps the game's own look: lines, the sun and moon, rain and snow, beacon beams, enchantment glint.

#include "/lib/frame.glsl"

out vec4 v_Color;
out vec2 v_TexCoord;
out vec2 v_LightMap;
out vec3 v_Position;

void main() {
    mx_setup();
    v_Color = gl_Color;
    v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    v_LightMap = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vec3 view = (gl_ModelViewMatrix * gl_Vertex).xyz;
    v_Position = mat3(gbufferModelViewInverse) * view;
    gl_Position = gl_ProjectionMatrix * vec4(view, 1.0);
}
