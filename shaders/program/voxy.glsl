// Voxy's far-off terrain, colored the way Distant Horizons' is (lod_shading.glsl). Voxy draws the blocks with its
// own shaders, which this is put into: it calls voxy_emitFragment for each pixel, with the block's color, the
// face it is on, its light and its id from block.properties. The uniforms come from voxy.json.

#define MX_LOD_PASS

#include "/lib/frame.glsl"
#include "/lib/block_ids.glsl"
#include "/lib/lod_shading.glsl"

layout(location = 0) out vec4 fragColor;

void voxy_emitFragment(VoxyFragmentParameters parameters) {
    mx_setup();
    vec4 color = parameters.sampledColour * parameters.tinting;

    // Back from the screen to a position relative to the eye, through Voxy's own projection.
    vec3 ndc = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z) * 2.0 - 1.0;
    vec4 view = vxProjInv * vec4(ndc, 1.0);
    vec3 position = mat3(vxModelViewInv) * (view.xyz / view.w);

    // The face: its axis (y, z, x) in the upper bits, which way along it in the lowest.
    uint axis = parameters.face >> 1u;
    vec3 normal = vec3(axis == 2u, axis == 0u, axis == 1u) * (float(parameters.face & 1u) * 2.0 - 1.0);
    int type = mx_block_type(float(parameters.customId));
    // Plants are lit like the ground they grow from, as near ones are (terrain.fsh).
    if (mx_is_plant(type)) {
        normal = vec3(0.0, 1.0, 0.0);
    }
    vec2 light = clamp((parameters.lightMap - 1.0 / 32.0) * (16.0 / 15.0), 0.0, 1.0);

    fragColor = mx_lod_color(color, position, normal, light, type);
#ifndef MX_TRANSLUCENT
    fragColor.a = 1.0;
#endif
}
