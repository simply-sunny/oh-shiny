// The pack's options. Iris lists every #define and annotated constant here under Shader Pack Settings; the
// profiles (Low to Ultra) and the screens are in shaders.properties.
#ifndef MX_SETTINGS
#define MX_SETTINGS

// Lighting
#define SHADOWS // The sun and moon cast shadows.
#define COLORED_LIGHT // Torches glow orange, soul fire blue, sea lanterns teal, and so on.
#define AMBIENT_OCCLUSION // Corners and crevices are a little darker.
//#define SUN_RAYS // Shafts of sunlight through trees, openings and haze, in the air itself.

// World
#define WATER_REFLECTIONS // Water mirrors the world around it.
#define WAVING // Water ripples; leaves and plants sway.

// Image
#define BLOOM // A soft glow around bright things.
#define SMOOTH_EDGES // Blends away the stair steps along edges.

const int shadowMapResolution = 2048; // [1024 2048 4096]
// 2 to 32 chunks.
const float shadowDistance = 96.0; // [32.0 48.0 64.0 80.0 96.0 112.0 128.0 160.0 192.0 256.0 320.0 384.0 448.0 512.0]
// 0 keeps the game's own sun, straight overhead at noon. Tilted, shadows stay long all day.
const float sunPathRotation = 0.0; // [-60.0 -50.0 -40.0 -35.0 -30.0 -20.0 -10.0 0.0 10.0 20.0 30.0 35.0 40.0 50.0 60.0]

// The shadow map is centered exactly on the player, where its fish-eye bend is centered (see shadow.glsl).
// Moving it in whole texels, as Iris does by default, makes a bent map shake instead.
const float shadowIntervalSize = 0.0;
const bool shadowHardwareFiltering = false;
const float shadowDistanceRenderMul = 1.0;

#endif
