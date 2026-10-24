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

#if FOG_START > 0
// Fog Start's haze: clear up to its start, then thickening with distance as real air does, so that by the game's
// render distance three quarters of what is behind it is hidden at sea level. Distant Horizons' and Voxy's far
// terrain lies further still and fades into it without vanishing. It is thickest low down and thins with
// height, so valleys fill with it while hills and mountains stand out above. `position`: relative to the eye.
float mx_mist(vec3 position) {
    float start = far * float(FOG_START) / 100.0;
    float distance_to = length(position);
    float through = max(distance_to - start, 0.0);
    if (through <= 0.0) {
        return 0.0;
    }
    const float sea_level = 63.0;
    const float thinning = 48.0;   // blocks over which it thins to about a third
    float density = 1.4 / max(far - start, 16.0);
    // Its thickness averaged over the way from the eye to the point, which climbs or falls.
    float low = (cameraPosition.y - sea_level) / thinning;
    float rise = position.y / thinning;
    float average = abs(rise) < 1.0e-3 ? exp(-low) : exp(-low) * (1.0 - exp(-rise)) / rise;
    // It is the open air's: it fades away while the player is somewhere the sky cannot reach, like a cave.
    float outdoors = smoothstep(0.0, 0.5, float(eyeBrightnessSmooth.y) / 240.0);
    return (1.0 - exp(-density * through * clamp(average, 0.0, 3.0))) * outdoors;
}
#endif

// Under the open sky: the game's fog together with a thin haze that thickens with distance and rain, and Fog
// Start's mist.
float mx_fog_total(vec3 position, float amount) {
    float haze = 1.0 - exp(-length(position) * (0.0004 + 0.0035 * MxSkyAmbient.w));
    // The game's fog rises in a straight line from the camera out. Squared, it leaves what is near clear and
    // still closes fully at the edge of the loaded world.
    float total = max(amount * amount, haze * 0.7);
#if FOG_START > 0
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
