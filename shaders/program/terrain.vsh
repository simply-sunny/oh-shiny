// Terrain: solid and cut-out blocks (gbuffers_terrain), and with MX_TRANSLUCENT water, glass and the like
// (gbuffers_water).

#include "/lib/frame.glsl"
#include "/lib/taa.glsl"
#include "/lib/block_ids.glsl"
#include "/lib/waving.glsl"
#include "/lib/shadow.glsl"

in vec4 mc_Entity;
in vec4 at_midBlock;

out vec4 v_Color;
out vec2 v_TexCoord;
out vec2 v_Light;
out vec3 v_Position;
out vec3 v_Normal;
// mx_shadow_unbent of v_Position, for mx_shadow_from.
out vec3 v_ShadowUnbent;
flat out int v_Type;

void main() {
    mx_setup();
    v_Type = mx_block_type(mc_Entity.x);
    v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vec2 light_map = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    v_Light = clamp((light_map - 1.0 / 32.0) * (16.0 / 15.0), 0.0, 1.0);
    v_Color = gl_Color;

    // Relative to the eye, in world orientation: the view matrix only turns it to face where the camera looks.
    vec3 view = (gl_ModelViewMatrix * gl_Vertex).xyz;
    vec3 position = mat3(gbufferModelViewInverse) * view;
    vec3 waved = mx_wave(position, v_Type, mx_height_in_block(at_midBlock));
    view += mat3(gbufferModelView) * (waved - position);
    gl_Position = mx_jitter(gl_ProjectionMatrix * vec4(view, 1.0));

    v_Position = waved;
    v_ShadowUnbent = mx_shadow_unbent(waved);
    v_Normal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
}
