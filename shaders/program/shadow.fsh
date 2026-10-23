#define MX_SHADOW_PASS

#include "/lib/frame.glsl"
#include "/lib/block_ids.glsl"
#include "/lib/light_colors.glsl"

// Cleared to white, which the map of light colors reads as no light.
/*
const int shadowcolor0Format = RGBA8;
*/
const vec4 shadowcolor0ClearColor = vec4(1.0, 1.0, 1.0, 1.0);

uniform sampler2D gtexture;

in vec2 v_TexCoord;
in vec4 v_Color;
in vec2 v_Clip;
in vec2 v_FromSource;
flat in int v_Type;
flat in vec4 v_Source;

layout(location = 0) out vec4 fragColor;

void main() {
    if (v_Source.w > 0.5) {
        // A light source's disc in the map of light colors: sure of its color near the source, less so towards
        // the edge of its reach. Where discs overlap, the light that is stronger at that very texel wins the depth
        // test. (A depth per light instead, set in shadow.vsh, would let the brightest light take its whole disc
        // over its neighbours'.)
        float reach = v_Source.z;
        float near = 1.0 - length(v_FromSource) / reach;
        if (near <= 0.0) {
            discard;
        }
        gl_FragDepth = 1.0 - 0.999 * near * near * reach / 15.0;
        float sure = clamp(near * 2.5, 0.0, 1.0);
        fragColor = vec4(v_Source.x / 15.0, v_Source.y / MX_GRID_DEPTH, 1.0 - sure, reach / 15.0);
        return;
    }
    // The map of light colors' corner belongs to it alone; nothing else is drawn there.
    float corner = mx_grid_clip_start();
    if (v_Clip.x > corner && v_Clip.y > corner) {
        discard;
    }
    // Water casts no shadow: sunlight reaches the bottom, where the caustics are.
    if (v_Type == MX_BLOCK_WATER) {
        discard;
    }
    // Leaves and plants cast shadows with holes in them.
    if (texture(gtexture, v_TexCoord).a * v_Color.a < 0.1) {
        discard;
    }
    gl_FragDepth = gl_FragCoord.z;
    fragColor = vec4(1.0);
}
