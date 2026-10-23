// Fog.
#ifndef MX_FOG
#define MX_FOG

#include "/lib/frame.glsl"
#include "/lib/color.glsl"
#include "/lib/sky.glsl"

float mx_fog_ramp(float distance, float start, float end) {
    if (end <= start) return 0.0;
    return clamp((distance - start) / (end - start), 0.0, 1.0);
}

// The game's two fogs together: the one of the surroundings (rain, water, lava; Iris's fogStart and fogEnd) by
// straight-line distance, and the one that hides the edge of the loaded world by distance along the ground.
float mx_fog_amount(vec3 position) {
    float flat_distance = max(length(position.xz), abs(position.y));
    float edge_start = far - clamp(far * 0.1, 4.0, 64.0);
    return max(mx_fog_ramp(length(position), fogStart, fogEnd),
               mx_fog_ramp(flat_distance, edge_start, far));
}

// Under the open sky: the game's fog together with a thin haze that thickens with distance and rain.
float mx_fog_total(vec3 position, float amount) {
    float haze = 1.0 - exp(-length(position) * (0.0004 + 0.0035 * MxSkyAmbient.w));
    // The game's fog rises in a straight line from the camera out. Squared, it leaves what is near clear and
    // still closes fully at the edge of the loaded world.
    return max(amount * amount, haze * 0.7);
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
