// Distant Horizons and Voxy: terrain far beyond the game's own render distance, drawn by those mods with a
// projection and a depth image of their own. Iris defines DISTANT_HORIZONS or VOXY when one of them is running;
// Leadlight and Metallum define neither, and everything here then falls back to the game's own distance.
// The far-off terrain itself is drawn by program/lod.fsh (Distant Horizons) and voxy_opaque.glsl (Voxy), both
// with lod_shading.glsl. MX_VOXY_PATCH is defined inside Voxy's own shaders, which declare their uniforms for us.
#ifndef MX_LOD_LIB
#define MX_LOD_LIB

#include "/lib/frame.glsl"

#if defined DISTANT_HORIZONS
#define MX_LOD
uniform sampler2D dhDepthTex0;
uniform mat4 dhProjectionInverse;
// In blocks.
uniform int dhRenderDistance;
#define MX_LOD_DEPTH dhDepthTex0
#define MX_LOD_PROJECTION_INVERSE dhProjectionInverse
#define MX_LOD_FAR float(dhRenderDistance)
#elif defined VOXY || defined MX_VOXY_PATCH
#define MX_LOD
#ifndef MX_VOXY_PATCH
uniform sampler2D vxDepthTexOpaque;
uniform mat4 vxProjInv;
// In chunks.
uniform int vxRenderDistance;
#endif
#define MX_LOD_DEPTH vxDepthTexOpaque
#define MX_LOD_PROJECTION_INVERSE vxProjInv
#define MX_LOD_FAR float(vxRenderDistance * 16)
#endif

// How far out the world is drawn, in blocks: to the end of the far-off terrain where there is some.
float mx_view_far() {
#ifdef MX_LOD
    return max(MX_LOD_FAR, far);
#else
    return far;
#endif
}

// How far the far-off terrain seen at `uv` (0..1 across the screen) is from the eye, in blocks; 0 where there
// is none. It is drawn only where the game's own world is not, so it matters only where depthtex0 is the sky.
float mx_lod_distance(vec2 uv) {
#if defined MX_LOD && !defined MX_VOXY_PATCH
    float depth = textureLod(MX_LOD_DEPTH, uv, 0.0).r;
    if (depth >= 1.0) {
        return 0.0;
    }
    vec4 view = MX_LOD_PROJECTION_INVERSE * vec4(vec3(uv, depth) * 2.0 - 1.0, 1.0);
    return length(view.xyz / view.w);
#else
    return 0.0;
#endif
}

#endif
