// The sky below the horizon, before anything else is drawn, where the game draws a fog-colored background; the
// sky above it is drawn onto the game's sky disc (sky_basic.fsh). Terrain fog fades to this same function.

#include "/lib/frame.glsl"
#include "/lib/color.glsl"
#include "/lib/noise.glsl"
#include "/lib/sky.glsl"

in vec2 texCoord;

layout(location = 0) out vec4 fragColor;

void main() {
    mx_setup();
    // Under water, in the Nether or blinded, the game's own fog-colored background stays.
    if (MxSkyHorizon.w > 0.5) {
        discard;
    }
    vec3 direction = mx_view_direction(gl_FragCoord.xy);
    // Above the horizon the game's sky disc is drawn next, and sky_basic.fsh paints this same sky onto it, so what
    // would be written here is drawn over. The disc's edge is 16 blocks up and 512 out, a little under 2 degrees
    // above the horizon; below about 3 this pass still draws, so no gap can open between the two.
    if (direction.y > 0.05) {
        discard;
    }
    // A little noise hides the steps an 8-bit image would otherwise show in so smooth a gradient.
    float grain = (mx_dither(gl_FragCoord.xy) - 0.5) / 255.0;
    fragColor = vec4(mx_encode(mx_sky(direction)) + grain, 1.0);
}
