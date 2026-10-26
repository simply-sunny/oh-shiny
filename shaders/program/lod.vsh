// Distant Horizons' far-off terrain (dh_terrain), and with MX_TRANSLUCENT its water (dh_water). Its blocks come
// with a color and a light level but no texture, and no block id: dhMaterialId says roughly what they are.

#define MX_LOD_PASS

#include "/lib/frame.glsl"
#include "/lib/taa.glsl"
#include "/lib/block_ids.glsl"

uniform mat4 dhProjection;

out vec4 v_Color;
out vec2 v_Light;
out vec3 v_Position;
out vec3 v_Normal;
flat out int v_Type;

int mx_dh_type() {
    if (dhMaterialId == DH_BLOCK_WATER) return MX_BLOCK_WATER;
    if (dhMaterialId == DH_BLOCK_LAVA) return MX_BLOCK_LAVA;
    if (dhMaterialId == DH_BLOCK_LEAVES) return MX_BLOCK_LEAVES;
    if (dhMaterialId == DH_BLOCK_METAL) return MX_BLOCK_METAL;
    if (dhMaterialId == DH_BLOCK_ILLUMINATED) return MX_BLOCK_GLOWING;
    return 0;
}

void main() {
    mx_setup();
    v_Type = mx_dh_type();
    vec2 light_map = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    v_Light = clamp((light_map - 1.0 / 32.0) * (16.0 / 15.0), 0.0, 1.0);
    v_Color = gl_Color;

    vec3 view = (gl_ModelViewMatrix * gl_Vertex).xyz;
    v_Position = mat3(gbufferModelViewInverse) * view;
    v_Normal = normalize(mat3(gbufferModelViewInverse) * (mat3(gl_ModelViewMatrix) * gl_Normal));
    gl_Position = mx_jitter(dhProjection * vec4(view, 1.0));
}
