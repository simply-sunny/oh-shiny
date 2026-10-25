// Distant Horizons' far-off terrain (dh_terrain), and with MX_TRANSLUCENT its water (dh_water), shaded by
// lod_shading.glsl.

#define MX_LOD_PASS

#include "/lib/frame.glsl"
#include "/lib/noise.glsl"
#include "/lib/lod_shading.glsl"

in vec4 v_Color;
in vec2 v_Light;
in vec3 v_Position;
in vec3 v_Normal;
flat in int v_Type;

layout(location = 0) out vec4 fragColor;

void main() {
    mx_setup();
    // Distant Horizons also draws the chunks the game draws itself. Where the game's world is, it is the one
    // seen; towards its edge the far-off terrain takes over, a few pixels at a time.
    float takeover = smoothstep(far - 24.0, far - 8.0, length(v_Position.xz));
    if (mx_dither(gl_FragCoord.xy) >= takeover) {
        discard;
    }

    // Turned to face the camera, for faces seen from behind.
    vec3 normal = normalize(v_Normal);
    if (dot(normal, v_Position) > 0.0) {
        normal = -normal;
    }
    fragColor = mx_lod_color(v_Color, v_Position, normal, v_Light, v_Type);
#ifndef MX_TRANSLUCENT
    // Water comes here, in the opaque half, only with Distant Horizons' transparency set to Disabled, and then
    // nothing is drawn under it: it is drawn as it would look, but solid.
    if (v_Type == MX_BLOCK_WATER) {
        fragColor.a = 1.0;
    }
#endif
}
