// Lays the effects over the picture: occlusion darkens, sun rays add light.

#include "/lib/frame.glsl"
#include "/lib/color.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex7;
uniform sampler2D colortex15;
uniform sampler2D depthtex0;

in vec2 texCoord;

layout(location = 0) out vec4 fragColor;

#if defined AMBIENT_OCCLUSION || defined SUN_RAYS
// The half-size effects at this pixel, from the four texels around it, those at the pixel's own depth counting for
// the most. Plain blending lets the rays behind a leaf or a ridge bleed over its edge in a halo two pixels wide.
vec4 effects_here() {
    float depth = texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).r;
    float here = depth >= 1.0 ? 1.0e5 : gbufferProjection[3][2] / (depth * 2.0 - 1.0 + gbufferProjection[2][2]);
    // A half-size texel stands for the first of the four pixels under it (effects.fsh); with Sun Rays, for a pixel
    // further back still, its blur being off centre (effects_blur.fsh).
#ifdef SUN_RAYS
    vec2 at = (gl_FragCoord.xy + 0.5) * 0.5;
#else
    vec2 at = (gl_FragCoord.xy - 0.5) * 0.5;
#endif
    ivec2 base = ivec2(floor(at));
    vec2 blend = fract(at);
    ivec2 last = textureSize(colortex7, 0) - 1;
    vec4 sum = vec4(0.0);
    float weights = 0.0;
    for (int y = 0; y <= 1; y++) {
        for (int x = 0; x <= 1; x++) {
            ivec2 texel = clamp(base + ivec2(x, y), ivec2(0), last);
            float there = texelFetch(colortex15, texel, 0).r;
            float weight = (x == 1 ? blend.x : 1.0 - blend.x) * (y == 1 ? blend.y : 1.0 - blend.y);
            // Never quite nothing: a thin thing with none of the four at its depth still gets their blend.
            weight *= exp(-abs(there - here) / (0.03 * here + 0.15)) + 1.0e-3;
            sum += texelFetch(colortex7, texel, 0) * weight;
            weights += weight;
        }
    }
    return sum / max(weights, 1.0e-6);
}
#endif

void main() {
    mx_setup();
    vec3 color = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0).rgb;
#if defined AMBIENT_OCCLUSION || defined SUN_RAYS
    vec4 effects = effects_here();
    vec3 linear = mx_to_linear(color) * effects.a;
    vec3 rays = 1.0 - exp(-effects.rgb * MxExposure);
    // Rays are screen-blended, so they brighten without clipping; in linear light, so they lift what is dark
    // by no more than they add to what is bright.
    color = mx_to_display(linear + rays * (1.0 - linear));
#endif
    fragColor = vec4(color, 1.0);
}
