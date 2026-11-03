// Softens the half-size effects image without smearing across depth edges.

uniform sampler2D colortex6;
uniform sampler2D colortex15;

in vec2 texCoord;

layout(location = 0) out vec4 fragColor;

void main() {
    ivec2 size = textureSize(colortex6, 0);
    ivec2 pixel = ivec2(gl_FragCoord.xy);
    float here = texelFetch(colortex15, pixel, 0).r;
    // The rays stop changing past the end of the shadow map, so what is further off than that is all one depth to
    // them: the sky between far-off leaves must not count as an edge, or the pattern their steps follow shows.
    float rays_here = min(here, shadowDistance);
    vec3 rays = vec3(0.0);
    float ray_weights = 0.0;
    float open = 0.0;
    float open_weights = 0.0;
#ifdef SUN_RAYS
    // A whole 4x4 square, one of each of the rays' steps (mx_bayer4); effects_apply.fsh allows for it being off
    // centre.
    const int FIRST = -2;
    const int LAST = 1;
    const int STRIDE = 1;
#else
    // Every other texel over the same 5x5 square: nine reads instead of twenty-five.
    const int FIRST = -2;
    const int LAST = 2;
    const int STRIDE = 2;
#endif
    for (int y = FIRST; y <= LAST; y += STRIDE) {
        for (int x = FIRST; x <= LAST; x += STRIDE) {
            ivec2 at = clamp(pixel + ivec2(x, y), ivec2(0), size - 1);
            float there = texelFetch(colortex15, at, 0).r;
            vec4 effects = texelFetch(colortex6, at, 0);
            // The same weight everywhere in the square but for depth, or the steps would no longer even out.
            float ray_weight = exp(-abs(min(there, shadowDistance) - rays_here) / (0.1 * rays_here + 0.5));
            rays += effects.rgb * ray_weight;
            ray_weights += ray_weight;
            float open_weight = exp(-abs(there - here) / (0.03 * here + 0.15)) * exp(-float(x * x + y * y) * 0.15);
            open += effects.a * open_weight;
            open_weights += open_weight;
        }
    }
    fragColor = vec4(rays / max(ray_weights, 1.0e-4), open / max(open_weights, 1.0e-4));
}
