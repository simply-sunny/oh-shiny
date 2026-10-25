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

// Where a point (relative to the eye) is drawn into the shadow map, in clip space. Drawing (shadow.vsh) and
// reading (mx_shadow_coord) both go through here. The map, and its bend, are centred exactly on the player.
vec4 mx_shadow_clip(vec3 position) {
    vec4 clip = shadowProjection * (shadowModelView * vec4(position + mx_feet_offset(), 1.0));
    clip.xy = mx_shadow_bend(clip.xy);
    return clip;
}

// Where a point (relative to the eye) lands in the shadow map: xy 0..1 across the map, z its depth there,
// 0 nearest the light.
vec3 mx_shadow_coord(vec3 position) {
    return mx_shadow_clip(position).xyz * 0.5 + 0.5;
}

// One smoothed lookup: the four texels around `uv` are each compared with `depth`, and the four yes-or-no
// answers are blended by how close `uv` is to each, by the hardware. Blending the answers, not the depths, is
// what makes a shadow edge slide smoothly across the map's texels as the sun turns, where a plain lookup would
// make it flicker from one texel to the next.
float mx_shadow_tap(vec2 uv, float depth) {
    return texture(shadowtex0, vec3(uv, depth));
}

#ifdef PIXEL_SHADOWS
// Pixel Shadows: the point is moved to the middle of the texture pixel it lies in, so that every point of a pixel
// is shadowed alike and shadow edges step from pixel to pixel. Pixels are counted from the block grid, in the
// world (MxCameraPos is the camera's position, wrapped every 4096 blocks, a whole number of pixels). The point
// is first nudged half a pixel into its surface: on the surface it lies on the line between two pixels.
vec3 mx_pixel_lock(vec3 position, vec3 normal) {
    const float SIZE = float(PIXEL_SHADOWS_SIZE);
    vec3 inward = normal * (0.5 / SIZE);
    vec3 world = position + MxCameraPos.xyz - inward;
    world = (floor(world * SIZE) + 0.5) / SIZE;
    // Back out of the surface along the normal only, so the point stays on it.
    vec3 locked = world - MxCameraPos.xyz + inward;
    return locked + normal * dot(position - locked, normal);
}
#endif

// How much of the sun's or moon's light reaches a point: 1 fully lit, 0 fully shadowed.
// `position` is relative to the eye; `normal` is the surface normal there.
float mx_shadow(vec3 position, vec3 normal) {
    float strength = MxLightDir.w;
    if (strength <= 0.0) return 1.0;
#ifdef PIXEL_SHADOWS
    position = mx_pixel_lock(position, normal);
#endif

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

#ifdef PIXEL_SHADOWS
    // How much of the pixel is in shadow, from four lookups spread over it, a quarter pixel either way along the
    // surface. The map's texels slide over the world as the player moves (it follows the player exactly; see
    // shadowIntervalSize in settings.glsl), and a single lookup at the pixel's middle flips whenever an edge
    // drawn into the map lands a texel this side or that of it, so edges crawl. How much of the pixel is
    // covered hardly changes as they slide.
    vec3 across = normalize(cross(normal, abs(normal.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
    vec3 along = cross(normal, across);
    float quarter = 0.25 / float(PIXEL_SHADOWS_SIZE);
    float covered = 0.0;
    for (int i = 0; i < 4; i++) {
        vec2 corner = vec2(i & 1, i >> 1) * 2.0 - 1.0;
        vec3 at = mx_shadow_coord(lifted + (across * corner.x + along * corner.y) * quarter);
        covered += mx_shadow_tap(at.xy, at.z - 0.15 * MX_SHADOW_DEPTH_PER_BLOCK);
    }
    covered *= 0.25;
#ifdef PIXEL_SHADOWS_SOFT
    // A pixel at a shadow's edge is as dark as it is covered: edges are smoothed but stay in whole pixels.
    float lit = covered;
#else
    // A pixel is either lit or in shadow, by which covers more of it.
    float lit = step(0.5, covered);
#endif
#else
    // Four smoothed lookups in a square give a soft edge about three texels wide, with no grain; Shadow Blur
    // widens it, and from 2 up four more lookups between them keep it smooth. Further out a texel of the map
    // covers more ground and a pixel of the screen less, so one smoothed lookup is already as soft as the four
    // are near by, unless the edges are to be softer still: there they are what hides the map's texels sliding
    // past as the player moves.
    float reach = MxShadowTexel * 0.75 * float(SHADOW_SOFTNESS);
    float lit;
    if (distance_from_camera < range * 0.45 || SHADOW_SOFTNESS > 1) {
        lit = mx_shadow_tap(coord.xy + vec2(-reach, -reach), depth)
            + mx_shadow_tap(coord.xy + vec2(reach, -reach), depth)
            + mx_shadow_tap(coord.xy + vec2(-reach, reach), depth)
            + mx_shadow_tap(coord.xy + vec2(reach, reach), depth);
#if SHADOW_SOFTNESS > 1
        float side = reach * 1.41;
        lit += mx_shadow_tap(coord.xy + vec2(-side, 0.0), depth)
             + mx_shadow_tap(coord.xy + vec2(side, 0.0), depth)
             + mx_shadow_tap(coord.xy + vec2(0.0, -side), depth)
             + mx_shadow_tap(coord.xy + vec2(0.0, side), depth);
        lit *= 0.125;
#else
        lit *= 0.25;
#endif
    } else {
        lit = mx_shadow_tap(coord.xy, depth);
    }
#endif

    return mix(1.0, mix(lit, 1.0, beyond), strength);
}

#endif
