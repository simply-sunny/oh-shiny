// The values the rest of the pack works with: where the sun and moon are, the color of their light, the sky,
// the light that reaches everywhere. Worked out from Iris's uniforms by mx_setup(), which every program calls
// first. (GLSL does not allow globals to be initialised from uniforms, so they are filled in there.)
#ifndef MX_FRAME
#define MX_FRAME

#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"

vec4 MxLightDir;     // xyz: towards the sun or moon, whichever is lighting the world. w: shadow strength
vec4 MxLightColor;   // rgb: linear color of that light. w: 1 by day, 0 by night
vec4 MxSunDir;       // xyz: towards the sun. w: how much of it is above the horizon
vec4 MxMoonDir;      // xyz: towards the moon. w: how much of it is above the horizon
vec4 MxSkyAmbient;   // rgb: linear light from the open sky. w: rain
vec4 MxBlockLight;   // rgb: linear color of block light at full strength. w: flicker
vec4 MxMinAmbient;   // rgb: linear light that reaches everywhere. w: darkness effect
vec4 MxSkyZenith;    // rgb: linear sky color overhead. w: star brightness
vec4 MxSkyHorizon;   // rgb: linear sky color at the horizon. w: 1 = fog fades to the game's fog color
vec4 MxSunsetColor;  // rgb: linear sunrise or sunset tint. a: strength
vec4 MxCameraPos;    // xyz: camera position (wrapped). w: seconds
vec4 MxScreen;       // xy: screen size. zw: one pixel
float MxExposure;     // how bright light is shown
float MxBloom;        // how strong the glow is: 0 off, 1 as the original
float MxShadowTexel;  // one shadow map texel, as a share of the map
float MxShadowRange;  // how far shadows reach from the player, in blocks
float MxEyeSkyLight;  // sky light where the camera is, 0..1, smoothed over time
bool MxUnderwater;    // the camera is under water
bool MxCelestial;     // this dimension has a sun and moon to light it

// The effects that can be switched off, as constants so the compiler drops what is off.
#ifdef WAVING
const bool MxWaving = true;
#else
const bool MxWaving = false;
#endif
#ifdef WATER_REFLECTIONS
const bool MxReflections = true;
#else
const bool MxReflections = false;
#endif
#ifdef SUN_RAYS
const bool MxSunRays = true;
#else
const bool MxSunRays = false;
#endif
#ifdef AMBIENT_OCCLUSION
const bool MxAmbientOcclusion = true;
#else
const bool MxAmbientOcclusion = false;
#endif

vec3 mx_linear(vec3 display) {
    return pow(max(display, vec3(0.0)), vec3(2.2));
}

// Where the eye is in "player space", which is what Iris's matrices are built around. Positions in this pack
// are relative to the eye; add this to get the player-space position the shadow and world matrices take.
vec3 mx_feet_offset() {
    return gbufferModelViewInverse[3].xyz;
}

// Sunset Color: the sky with the sun going under, at the horizon and up, and the low sun's light on the ground.
#if SUNSET_COLOR == 1 // Orange
const vec3 MX_SUNSET_UNDER = vec3(0.90, 0.38, 0.25);
const vec3 MX_SUNSET_HORIZON = vec3(1.0, 0.50, 0.25);
const vec3 MX_SUNSET_UP = vec3(1.0, 0.72, 0.38);
const vec3 MX_SUNSET_LIGHT = vec3(1.0, 0.52, 0.28);
#elif SUNSET_COLOR == 2 // Gold
const vec3 MX_SUNSET_UNDER = vec3(0.95, 0.55, 0.30);
const vec3 MX_SUNSET_HORIZON = vec3(1.0, 0.70, 0.35);
const vec3 MX_SUNSET_UP = vec3(1.0, 0.85, 0.50);
const vec3 MX_SUNSET_LIGHT = vec3(1.0, 0.68, 0.36);
#elif SUNSET_COLOR == 3 // Red
const vec3 MX_SUNSET_UNDER = vec3(0.70, 0.16, 0.20);
const vec3 MX_SUNSET_HORIZON = vec3(0.95, 0.28, 0.20);
const vec3 MX_SUNSET_UP = vec3(1.0, 0.55, 0.30);
const vec3 MX_SUNSET_LIGHT = vec3(1.0, 0.38, 0.25);
#elif SUNSET_COLOR == 4 // Purple
const vec3 MX_SUNSET_UNDER = vec3(0.58, 0.38, 0.85);
const vec3 MX_SUNSET_HORIZON = vec3(0.85, 0.45, 0.75);
const vec3 MX_SUNSET_UP = vec3(1.0, 0.65, 0.65);
const vec3 MX_SUNSET_LIGHT = vec3(0.82, 0.52, 0.90);
#elif SUNSET_COLOR == 5 // Blue
const vec3 MX_SUNSET_UNDER = vec3(0.40, 0.50, 0.90);
const vec3 MX_SUNSET_HORIZON = vec3(0.60, 0.65, 0.95);
const vec3 MX_SUNSET_UP = vec3(0.95, 0.80, 0.70);
const vec3 MX_SUNSET_LIGHT = vec3(0.62, 0.72, 1.0);
#else // Pink
const vec3 MX_SUNSET_UNDER = vec3(0.88, 0.50, 0.62);
const vec3 MX_SUNSET_HORIZON = vec3(1.0, 0.60, 0.56);
const vec3 MX_SUNSET_UP = vec3(1.0, 0.78, 0.50);
const vec3 MX_SUNSET_LIGHT = vec3(1.0, 0.58, 0.40);
#endif

// The sunrise and sunset color for a sun at `height` (-1..1) on its untilted path, with the game's own timing and
// strength. Not the game's color, which ends in a deep red, blood red once in linear light: by default gold with the
// sun up, coral at the horizon, rose as it goes under, like the real thing.
vec4 mx_sunset_color(float height) {
    if (height < -0.4 || height > 0.4) {
        return vec4(0.0);
    }
    float g = height / 0.4 * 0.5 + 0.5;
    float alpha = 1.0 - (1.0 - sin(g * 3.14159265)) * 0.99;
    alpha *= alpha;
    vec3 color = g < 0.5 ? mix(MX_SUNSET_UNDER, MX_SUNSET_HORIZON, g * 2.0)
                         : mix(MX_SUNSET_HORIZON, MX_SUNSET_UP, g * 2.0 - 1.0);
    return vec4(color, alpha);
}

void mx_setup() {
    float rain = rainStrength;
    MxCelestial = hasSkylight;

    vec3 sun = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    vec3 moon = normalize(mat3(gbufferModelViewInverse) * moonPosition);
    // The sun's height on the game's own path: the tilt turns the path about the east-west axis.
    float height = sun.y / max(cos(radians(sunPathRotation)), 0.1);
    float sunUp = smoothstep(-0.06, 0.12, sun.y);
    float moonUp = smoothstep(-0.06, 0.12, moon.y);
    float day = smoothstep(-0.12, 0.25, sun.y);
    float clearSky = 1.0 - 0.88 * rain;

    if (!MxCelestial) {
        MxLightDir = vec4(0.0, 1.0, 0.0, 0.0);
        MxLightColor = vec4(0.0);
        MxSunDir = vec4(0.0, 1.0, 0.0, 0.0);
    } else if (sun.y > -0.06) {
        // Low sun takes the sunset's color and is weaker, having more air to come through; high sun is a warm white,
        // which against the blue of the light from the sky is what tells sunlit ground from shade.
        float high = smoothstep(0.0, 0.4, sun.y);
        float strength = mix(1.9, 3.3, high) * sunUp * clearSky;
        MxLightDir = vec4(sun, sunUp * clearSky);
        MxLightColor = vec4(mix(MX_SUNSET_LIGHT, vec3(1.0, 0.93, 0.80), high) * strength, day);
        MxSunDir = vec4(sun, sunUp);
    } else {
        float strength = 0.34 * moonUp * clearSky;
        MxLightDir = vec4(moon, moonUp * clearSky);
        MxLightColor = vec4(0.46 * strength, 0.62 * strength, strength, day);
        MxSunDir = vec4(sun, 0.0);
    }
#ifndef SHADOWS
    MxLightDir.w = 0.0;
#endif
    MxMoonDir = vec4(moon, MxCelestial ? moonUp : 0.0);

    // How much of the sky reaches the camera. The sun rays follow it: see program/effects.fsh.
    MxEyeSkyLight = float(eyeBrightnessSmooth.y) / 240.0;

    // The game's own sky and fog colors already follow the time of day, the weather and the biome.
    float stars = clamp(1.0 - (height * 2.0 + 0.25), 0.0, 1.0);
    stars = MxCelestial ? stars * stars * 0.5 * (1.0 - rain) : 0.0;
    MxSkyZenith = vec4(mx_linear(skyColor), stars);
    // Under the open sky the fog fades to the sky; in water, lava, powder snow or blindness to the game's fog.
    bool atmosphere = MxCelestial && isEyeInWater == 0 && blindness < 0.01 && darknessFactor < 0.01;
    MxSkyHorizon = vec4(mx_linear(fogColor), atmosphere ? 0.0 : 1.0);

    vec4 sunset = mx_sunset_color(height);
    MxSunsetColor = vec4(mx_linear(sunset.rgb), MxCelestial ? sunset.a : 0.0);

    // Light from the open sky: the sky's own color with a little of the color taken out (a deep blue light would
    // turn grass and leaves murky), and a floor so that a moonless night is dark blue instead of black.
    vec3 skyLight = MxSkyZenith.rgb * 1.25 + 0.5 * MxSkyHorizon.rgb * day;
    // At sunrise and sunset the low sun lights the air itself, and that glow reaches the ground too.
    skyLight += MxSunsetColor.rgb * MxSunsetColor.a * 0.30;
    float skyGray = dot(skyLight, vec3(0.2126, 0.7152, 0.0722));
    MxSkyAmbient = vec4(mix(skyLight, vec3(skyGray), 0.25) * 1.05 + vec3(0.050, 0.066, 0.110), rain);

    MxBlockLight = vec4(3.3, 1.55, 0.58, 1.0);

    // What the game's light map adds everywhere: the dimension's ambient light (the Nether and the End are lit
    // by nothing else), lifted by the Brightness setting the same way the game lifts it, and night vision.
    float ambient = ambientLight;
    if (!MxCelestial) {
        ambient = max(ambient, hasCeiling ? 0.1 : 0.25);
    }
    if (ambient > 0.0) {
        float dim = 1.0 - ambient;
        ambient *= mix(1.0, (1.0 - dim * dim * dim * dim) / ambient, clamp(screenBrightness, 0.0, 1.0));
    }
    float floorLight = 0.0035 + 0.022 * screenBrightness;
    // A dimension with no sun is lit by its ambient light alone, so that is given more weight there, and the
    // fog's own color is added as the glow of everything around.
    vec3 minimum = mx_linear(vec3(ambient)) * (MxCelestial ? 1.0 : 2.4);
    if (!MxCelestial) {
        minimum += MxSkyHorizon.rgb * 0.12;
    }
    minimum += floorLight + nightVision * 0.45;
    MxMinAmbient = vec4(minimum, darknessFactor);

    MxCameraPos = vec4(mod(cameraPosition, 4096.0) + mx_feet_offset(), frameTimeCounter);
    MxScreen = vec4(viewWidth, viewHeight, 1.0 / viewWidth, 1.0 / viewHeight);

    MxExposure = 1.0;
    MxBloom = 0.0;
#ifdef BLOOM
    // Glow is the only light of its own kind in a dimension without a sun, so it is let be a little stronger there.
    MxBloom = MxCelestial ? 1.0 : 1.5;
#endif
    MxShadowTexel = 1.0 / float(shadowMapResolution);
    MxShadowRange = shadowDistance;
    MxUnderwater = isEyeInWater == 1;
}

#endif
