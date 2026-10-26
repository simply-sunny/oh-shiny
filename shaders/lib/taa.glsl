// Temporal anti-aliasing: each frame everything is drawn shifted by a different fraction of a pixel, the eight
// shifts of a Halton sequence in turn, and program/taa.fsh averages the frames, so each pixel ends up covered by
// many samples spread across it rather than one at its centre. The shift is undone by nothing: it is too small to
// see, and averaged out it centres on the pixel.
#ifndef MX_TAA
#define MX_TAA

#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"

uniform int frameCounter;

// This frame's shift, in pixels, each part between -0.5 and 0.5.
vec2 mx_taa_offset() {
    const vec2 HALTON[8] = vec2[8](
        vec2(0.5, 0.333333), vec2(0.25, 0.666667), vec2(0.75, 0.111111), vec2(0.125, 0.444444),
        vec2(0.625, 0.777778), vec2(0.375, 0.222222), vec2(0.875, 0.555556), vec2(0.0625, 0.888889));
    return HALTON[frameCounter & 7] - 0.5;
}

// A vertex's clip position, shifted by this frame's offset with TAA on and left as it is otherwise.
vec4 mx_jitter(vec4 clip) {
#ifdef TAA
    clip.xy += mx_taa_offset() * 2.0 / vec2(viewWidth, viewHeight) * clip.w;
#endif
    return clip;
}

#endif
