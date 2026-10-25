// The world as the sun or moon sees it, for the shadow map. With Colored Light on, blocks that give off light
// are drawn elsewhere instead: into the map of light colors in the shadow map's corner (light_colors.glsl).

#define MX_SHADOW_PASS

#include "/lib/frame.glsl"
#include "/lib/block_ids.glsl"
#include "/lib/waving.glsl"
#include "/lib/shadow.glsl"
#include "/lib/light_colors.glsl"

in vec4 mc_Entity;
in vec2 mc_midTexCoord;
in vec4 at_midBlock;

out vec2 v_TexCoord;
out vec4 v_Color;
out vec2 v_Clip;
// Light sources only: how far this point of the disc is from the source, in blocks.
out vec2 v_FromSource;
flat out int v_Type;
// Light sources only: x the color of the light, y its height above the map's floor, z how far it reaches, w 1.
flat out vec4 v_Source;

#ifdef COLORED_LIGHT
// Draws a face of a light-giving block as a square around the block's texel in the light map, as wide as its
// light reaches; the fragment shader rounds it into a disc. Every face of the block draws the same square.
bool mx_draw_light_source(vec3 position, int color) {
    vec3 block = floor(position + at_midBlock.xyz / 64.0 + mx_feet_offset() + cameraPosition);
    vec2 cell = block.xz - mx_grid_origin();
    float height = block.y + 0.5 - mx_grid_floor();
    if (any(lessThan(cell, vec2(0.0))) || any(greaterThanEqual(cell, vec2(float(MX_GRID))))
            || height < 0.0 || height > MX_GRID_DEPTH) {
        return false;
    }
    vec2 light_map = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    float level = clamp(round((light_map.x - 1.0 / 32.0) * 16.0), 8.0, 15.0);
    // Which corner of its face this vertex is, from where it sits in the face's texture.
    vec2 corner = sign(gl_MultiTexCoord0.st - mc_midTexCoord);
    corner = mix(vec2(1.0), corner, abs(corner));
    v_FromSource = corner * (level + 1.0);
    v_Source = vec4(float(color), height, level, 1.0);
    vec2 texel = vec2(mx_grid_start(ivec2(shadowMapResolution))) + cell + 0.5 + v_FromSource;
    // The depth is written per pixel (shadow.fsh).
    gl_Position = vec4(texel / float(shadowMapResolution) * 2.0 - 1.0, 0.0, 1.0);
    v_Clip = gl_Position.xy;
    return true;
}
#endif

void main() {
    mx_setup();
    v_Type = mx_block_type(mc_Entity.x);
    v_TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    v_Color = gl_Color;
    v_FromSource = vec2(0.0);
    v_Source = vec4(0.0);

    // From the light's view back to a position relative to the eye.
    vec3 light_view = (gl_ModelViewMatrix * gl_Vertex).xyz;
    vec3 position = (shadowModelViewInverse * vec4(light_view, 1.0)).xyz - mx_feet_offset();

#ifdef COLORED_LIGHT
    int color = mx_light_index(mc_Entity.x);
    if (color >= 0 && mx_draw_light_source(position, color)) {
        return;
    }
#endif

#ifndef SHADOWS
    // Only the map of light colors is wanted: everything else is put outside the map, where it is not drawn.
    gl_Position = vec4(0.0, 0.0, -2.0, 1.0);
    v_Clip = vec2(0.0);
    return;
#endif

    // Moved by the wind like the terrain itself.
    position = mx_wave(position, v_Type, mx_height_in_block(at_midBlock));

    vec4 clip = mx_shadow_clip(position);
    // Anything nearer the light than the map reaches is flattened onto its near side instead of being cut off:
    // it still has to cast its shadow.
    clip.z = max(clip.z, -0.9999);
    gl_Position = clip;
    v_Clip = clip.xy;
}
