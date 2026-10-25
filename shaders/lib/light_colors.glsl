// The color of block light near the player.
//
// The light level the game gives each vertex says how bright block light is, not what gave it, so a torch and
// a soul lantern would light their surroundings alike. The shadow pass therefore also draws a map of the light
// sources around the player, seen from above, into a corner of shadowcolor0 that the shadow map's own lookups
// never reach (its corners lie past the shadow distance; see shadow.glsl). Each light-giving block paints a
// disc as wide as its light reaches, keeping where it is strongest, its color, its height and how bright it
// is. Lighting tints block light by the map; how bright it is still comes from the game's own light, so the map
// does not need to know about walls, only about color.
//
// Only vertex and fragment shaders are used, so it works where compute and geometry shaders do not (OpenGL on
// macOS, Metal through Leadlight).
#ifndef MX_LIGHT_COLORS
#define MX_LIGHT_COLORS

#include "/lib/frame.glsl"

// The map covers this many blocks across, one texel each, centered on the player.
const int MX_GRID = 96;
// Heights are kept relative to this far below the player, in quarter blocks.
const float MX_GRID_DEPTH = 64.0;

// The colors a light-giving block can have, in the order of block.properties (10100 + the index).
vec3 mx_light_palette(int index) {
    if (index == 1) return vec3(255.0, 125.0, 55.0) / 255.0;   // fire, lava, furnaces
    if (index == 2) return vec3(95.0, 175.0, 255.0) / 255.0;   // soul fire
    if (index == 3) return vec3(125.0, 230.0, 255.0) / 255.0;  // sea lanterns, conduits, sculk
    if (index == 4) return vec3(190.0, 120.0, 255.0) / 255.0;  // amethyst
    if (index == 5) return vec3(235.0, 240.0, 255.0) / 255.0;  // end rods, beacons, froglights
    if (index == 6) return vec3(255.0, 75.0, 55.0) / 255.0;    // redstone
    if (index == 7) return vec3(205.0, 95.0, 255.0) / 255.0;   // portals, crying obsidian
    if (index == 8) return vec3(150.0, 255.0, 120.0) / 255.0;  // copper torches and lanterns
    return vec3(255.0, 180.0, 110.0) / 255.0;                   // torches, lanterns, glowstone
}

// The world block the map's first texel stands for, and the height its heights count from.
vec2 mx_grid_origin() {
    return floor(cameraPosition.xz) - float(MX_GRID / 2);
}

float mx_grid_floor() {
    return floor(cameraPosition.y) - MX_GRID_DEPTH * 0.5;
}

// Where the map starts in shadowcolor0, in texels: the corner furthest from the middle.
ivec2 mx_grid_start(ivec2 size) {
    return size - ivec2(MX_GRID);
}

// Shadow map clip coordinates from which on the map's corner begins, along both axes.
float mx_grid_clip_start() {
    return 1.0 - 2.0 * float(MX_GRID) / float(shadowMapResolution);
}

#ifndef MX_SHADOW_PASS
uniform sampler2D shadowcolor0;

// One texel of the map, for a point at height `y`: rgb the light's linear color, a how sure (0 where no
// light-giving block is near).
vec4 mx_light_cell(ivec2 cell, float y) {
    if (any(lessThan(cell, ivec2(0))) || any(greaterThanEqual(cell, ivec2(MX_GRID)))) {
        return vec4(0.0);
    }
    ivec2 size = textureSize(shadowcolor0, 0);
    vec4 texel = texelFetch(shadowcolor0, mx_grid_start(size) + cell, 0);
    // Cleared to white: no light here.
    float sure = 1.0 - texel.b;
    if (sure <= 0.0) {
        return vec4(0.0);
    }
    float level = max(texel.a * 15.0, 1.0);
    float source_y = texel.g * MX_GRID_DEPTH + mx_grid_floor();
    // Light reaches about as far up and down as it does sideways.
    sure *= clamp(1.0 - (abs(y - source_y) - 1.0) / level, 0.0, 1.0);
    return vec4(mx_linear(mx_light_palette(int(texel.r * 15.0 + 0.5))), sure);
}

// rgb: the color of the block light at a point (relative to the eye), linear. a: how sure that is.
vec4 mx_light_color_at(vec3 position) {
    vec3 world = position + mx_feet_offset() + cameraPosition;
    vec2 at = world.xz - mx_grid_origin() - 0.5;
    ivec2 base = ivec2(floor(at));
    vec2 blend = at - floor(at);
    vec4 a = mx_light_cell(base, world.y);
    vec4 b = mx_light_cell(base + ivec2(1, 0), world.y);
    vec4 c = mx_light_cell(base + ivec2(0, 1), world.y);
    vec4 d = mx_light_cell(base + ivec2(1, 1), world.y);
    // Colors are blended by how sure each is, so a cell with no light does not pull the color towards black.
    vec4 weights = vec4((1.0 - blend.x) * (1.0 - blend.y), blend.x * (1.0 - blend.y), (1.0 - blend.x) * blend.y, blend.x * blend.y)
                 * vec4(a.a, b.a, c.a, d.a);
    float total = weights.x + weights.y + weights.z + weights.w;
    if (total <= 0.0) {
        return vec4(0.0);
    }
    vec3 color = (a.rgb * weights.x + b.rgb * weights.y + c.rgb * weights.z + d.rgb * weights.w) / total;
    return vec4(color, total);
}
#endif

#endif
