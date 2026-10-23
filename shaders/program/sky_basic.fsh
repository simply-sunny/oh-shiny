// The game's sky disc, sunset disc, stars and dark lower half. Where the pack draws the sky itself, the disc
// draws it here, from the same function prepare.fsh uses: under Iris prepare.fsh fills the screen and the disc
// covers the upper half again, seamlessly; under Leadlight what prepare.fsh writes is not what the sky passes
// draw onto, so the disc, which covers the whole screen there, is what shows. The sunset disc is dropped (the
// pack's sky has its own dusk band), and so are the game's stars: the pack's sky has its own, which twinkle.

#include "/lib/frame.glsl"
#include "/lib/color.glsl"
#include "/lib/noise.glsl"
#include "/lib/sky.glsl"

in vec4 v_Color;
in vec2 v_TexCoord;
in vec2 v_LightMap;
in vec3 v_Position;

layout(location = 0) out vec4 fragColor;

void main() {
    mx_setup();
    // Where the pack does not draw the sky (under water, the Nether, blindness) the game's is kept whole.
    if (MxSkyHorizon.w > 0.5) {
        fragColor = v_Color;
        return;
    }
    if (renderStage == MC_RENDER_STAGE_SUNSET || renderStage == MC_RENDER_STAGE_STARS) {
        discard;
    }
    vec3 direction = mx_view_direction(gl_FragCoord.xy);
    float grain = (mx_dither(gl_FragCoord.xy) - 0.5) / 255.0;
    fragColor = vec4(mx_encode(mx_sky(direction)) + grain, 1.0);
}
