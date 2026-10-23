// Everything the game draws as a model rather than as terrain: mobs, players, block entities, dropped items,
// the hand, particles.

#include "/lib/frame.glsl"

out vec4 v_Color;
out vec2 v_TexCoord;
out vec2 v_Light;
out vec3 v_Position;
out vec3 v_Normal;

void main() {
    mx_setup();
    v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vec2 light_map = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    v_Light = clamp((light_map - 1.0 / 32.0) * (16.0 / 15.0), 0.0, 1.0);
    v_Color = gl_Color;

    vec3 view = (gl_ModelViewMatrix * gl_Vertex).xyz;
    v_Position = mat3(gbufferModelViewInverse) * view;
    v_Normal = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal);
    gl_Position = gl_ProjectionMatrix * vec4(view, 1.0);
}
