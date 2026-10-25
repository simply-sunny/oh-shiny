// Fog.
#ifndef MX_FOG
#define MX_FOG

#include "/lib/frame.glsl"
#include "/lib/color.glsl"
#include "/lib/sky.glsl"
#include "/lib/lod.glsl"

float mx_fog_ramp(float distance, float start, float end) {
    if (end <= start) return 0.0;
    return clamp((distance - start) / (end - start), 0.0, 1.0);
}

// The game's two fogs together: the one of the surroundings (rain, water, lava; Iris's fogStart and fogEnd) by
// straight-line distance, and the one that hides the edge of the loaded world by distance along the ground.
// With Distant Horizons or Voxy the world goes on past the game's own edge, so that fog moves out to theirs.
// It fades in over the last tenth of the way, at most 64 blocks.
float mx_fog_amount(vec3 position) {
    float flat_distance = max(length(position.xz), abs(position.y));
    float edge = mx_view_far();
    float edge_start = edge - clamp(edge * 0.1, 4.0, 64.0);
#ifdef MX_LOD
    // In clear air the game's fog of the surroundings sits at its own render distance, and would fog the near
    // world over in front of the far-off one: it is kept only where it is the weather's or the water's.
    float surroundings = MxSkyHorizon.w > 0.5 || MxSkyAmbient.w > 0.01 ? mx_fog_ramp(length(position), fogStart, fogEnd) : 0.0;
#else
    float surroundings = mx_fog_ramp(length(position), fogStart, fogEnd);
#endif
    return max(surroundings, mx_fog_ramp(flat_distance, edge_start, edge));
}

#if FOG_AMOUNT > 0
// The Fog setting's haze, over the last share of what is drawn that the setting names: Distant Horizons' or
// Voxy's far terrain where there is some, the game's own render distance otherwise. Clear up to its start, then
// thickening steadily, so that by the edge of what is drawn almost nothing behind it shows. It lies in the low
// ground: what is seen there is fogged fully, and less the higher above the sea it stands, so valleys fill with it
// and hills and mountains stand out above, however high the player is. `position`: relative to the eye.
float mx_mist(vec3 position) {
    float edge = mx_view_far();
    float start = edge * float(100 - FOG_AMOUNT) / 100.0;
    float through = clamp((length(position) - start) / max(edge - start, 16.0), 0.0, 1.0);
    if (through <= 0.0) {
        return 0.0;
    }
    const float sea_level = 63.0;
    const float thinning = 64.0;   // blocks above the sea over which it thins to about a third
    float height = cameraPosition.y + position.y - sea_level;
    float low = clamp(exp(-max(height, 0.0) / thinning), 0.2, 1.0);
    // It is the open air's: it fades away while the player is somewhere the sky barely reaches, like a cave, even
    // one with a hole in its roof, and anywhere well below the sea, where the sky can only be through a shaft.
    float outdoors = smoothstep(0.5, 0.85, float(eyeBrightnessSmooth.y) / 240.0) * smoothstep(40.0, 56.0, cameraPosition.y);
    return (1.0 - exp(-3.5 * through * low)) * outdoors;
}
#endif

// Under the open sky: the game's fog together with a thin haze that thickens with distance and rain, and the Fog
// setting's mist.
float mx_fog_total(vec3 position, float amount) {
    float haze = 1.0 - exp(-length(position) * (0.0004 + 0.0035 * MxSkyAmbient.w));
    // The game's fog rises in a straight line from the camera out. Squared, it leaves what is near clear and
    // still closes fully at the edge of the loaded world.
    float total = max(amount * amount, haze * 0.7);
#if FOG_AMOUNT > 0
    total = max(total, mx_mist(position));
#endif
    return total;
}

// The sky that fog fades into: the whole sky, stars and all.
vec3 mx_fog_sky(vec3 direction) {
    return mx_sky(direction);
}

// Lit linear color -> the display color to write, with fog applied.
// Under the open sky the fog is the sky itself, so distant land melts into the sky behind it. Anywhere else
// (underwater, the Nether, blindness) it is the game's own fog color, exactly.
vec3 mx_fogged(vec3 lit, vec3 position, float amount) {
    if (MxSkyHorizon.w > 0.5) {
        return mix(mx_encode(lit), fogColor, amount);
    }
    return mx_encode(mix(lit, mx_fog_sky(normalize(position)), mx_fog_total(position, amount)));
}

#endif
