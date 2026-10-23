// The shadow map: drawing into it (shadow.vsh) and reading it.
#ifndef MX_SHADOW
#define MX_SHADOW

#include "/lib/frame.glsl"

// Read with the depth comparison done by the hardware (shadowHardwareFiltering, settings.glsl).
uniform sampler2DShadow shadowtex0;

// The shadow map is drawn fish-eyed: stretched near the middle (around the player) and squeezed towards the edge,
// so shadows are sharp close up without a bigger map. Drawing and reading bend coordinates the same way.
const float MX_SHADOW_BEND = 0.82;

// Iris's shadow projection spans 256 blocks of depth; one block is this much of the stored 0..1 depth.
const float MX_SHADOW_DEPTH_PER_BLOCK = 1.0 / 256.0;

vec2 mx_shadow_bend(vec2 clip) {
    return clip / (length(clip) * MX_SHADOW_BEND + (1.0 - MX_SHADOW_BEND));
}

// Where a point (relative to the eye) lands in the shadow map: xy 0..1 across the map, z its depth there,
// 0 nearest the light.
vec3 mx_shadow_coord(vec3 position) {
    vec4 clip = shadowProjection * (shadowModelView * vec4(position + mx_feet_offset(), 1.0));
    clip.xy = mx_shadow_bend(clip.xy);
    return clip.xyz * 0.5 + 0.5;
}

// One smoothed lookup: the four texels around `uv` are each compared with `depth`, and the four yes-or-no
// answers are blended by how close `uv` is to each, by the hardware. Blending the answers, not the depths, is
// what makes a shadow edge slide smoothly across the map's texels as the sun turns, where a plain lookup would
// make it flicker from one texel to the next.
float mx_shadow_tap(vec2 uv, float depth) {
    return texture(shadowtex0, vec3(uv, depth));
}

// How much of the sun's or moon's light reaches a point: 1 fully lit, 0 fully shadowed.
// `position` is relative to the eye; `normal` is the surface normal there.
float mx_shadow(vec3 position, vec3 normal) {
    float strength = MxLightDir.w;
    if (strength <= 0.0) return 1.0;

    float range = MxShadowRange;
    float distance_from_camera = length(position);
    float beyond = smoothstep(range * 0.80, range * 0.97, distance_from_camera);
    if (beyond >= 1.0) return 1.0;
    float facing = clamp(dot(normal, MxLightDir.xyz), 0.0, 1.0);

    // Look the point up a little way off the surface, or the surface shadows itself in stripes. A texel covers
    // more ground further from the player and when the light grazes the surface, so step further off there.
    float squeeze = (distance_from_camera / range) * MX_SHADOW_BEND + (1.0 - MX_SHADOW_BEND);
    float texel_size = 2.0 * range * MxShadowTexel * squeeze;
    vec3 lifted = position + normal * texel_size * (1.5 + 2.5 * (1.0 - facing));

    vec3 coord = mx_shadow_coord(lifted);
    float depth = coord.z - 0.15 * MX_SHADOW_DEPTH_PER_BLOCK;

    // Four smoothed lookups in a square give a soft edge about three texels wide, with no grain.
    float reach = MxShadowTexel * 0.75;
    float lit = mx_shadow_tap(coord.xy + vec2(-reach, -reach), depth)
              + mx_shadow_tap(coord.xy + vec2(reach, -reach), depth)
              + mx_shadow_tap(coord.xy + vec2(-reach, reach), depth)
              + mx_shadow_tap(coord.xy + vec2(reach, reach), depth);
    lit *= 0.25;

    return mix(1.0, mix(lit, 1.0, beyond), strength);
}

#endif
