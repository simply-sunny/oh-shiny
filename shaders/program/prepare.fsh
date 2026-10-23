// The whole sky in one pass, before anything else is drawn, where the game draws a flat disc over a fog-colored
// background. Terrain fog fades to this same function.

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
    // A little noise hides the steps an 8-bit image would otherwise show in so smooth a gradient.
    float grain = (mx_dither(gl_FragCoord.xy) - 0.5) / 255.0;
    fragColor = vec4(mx_encode(mx_sky(direction)) + grain, 1.0);
}
