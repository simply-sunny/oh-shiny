// The picture to the screen. With FXAA on, the stair steps along every edge in the picture are smoothed. With
// Smooth Edges on instead, only where the depth says one thing ends and another begins, or a surface turns a
// corner: the texels of a block's own texture are edges too, to the eye of a filter, and blending those would
// blur every block. With Sharpening on, the picture is sharpened, the more where it is flat and the less across
// edges (AMD's contrast adaptive sharpening), which wins back what TAA softens. Then, with Bloom on,
// the glow is laid over it (worked out by the bloom passes into colortex10). The glow is done here rather than
// in a pass of its own, which would read and write the whole picture once more; it is soft enough that smoothing
// the edges before it rather than after makes no difference to see. Last comes the color grading
// (lib/grade.glsl), when any Color Grading setting is on.

#include "/lib/frame.glsl"
#include "/lib/color.glsl"
#include "/lib/grade.glsl"

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
#ifdef BLOOM
uniform sampler2D colortex10;
#endif

in vec2 texCoord;

layout(location = 0) out vec4 fragColor;

float brightness(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

vec3 at(vec2 uv) {
    return textureLod(colortex0, uv, 0.0).rgb;
}

// Depth measured from the far end, so it grows towards the camera.
float nearness_at(ivec2 texel) {
    return 1.0 - texelFetch(depthtex0, clamp(texel, ivec2(0), textureSize(depthtex0, 0) - 1), 0).r;
}

// Depth as stored changes by the same amount from each pixel to the next across a flat surface, however the
// surface is turned. Where it does not, the surface bends or ends.
bool on_edge() {
    ivec2 texel = ivec2(gl_FragCoord.xy);
    float here = nearness_at(texel);
    float left = nearness_at(texel - ivec2(1, 0));
    float right = nearness_at(texel + ivec2(1, 0));
    float down = nearness_at(texel - ivec2(0, 1));
    float up = nearness_at(texel + ivec2(0, 1));
    float bend = abs(left + right - 2.0 * here) + abs(down + up - 2.0 * here);
    float nearest = max(here, max(max(left, right), max(down, up)));
    return bend > nearest * 0.0015;
}

vec3 smoothed(vec3 middle) {
    if (!on_edge()) {
        return middle;
    }

    vec2 pixel = MxScreen.zw;
    float m = brightness(middle);
    float nw = brightness(at(texCoord + pixel * vec2(-1.0, -1.0)));
    float ne = brightness(at(texCoord + pixel * vec2(1.0, -1.0)));
    float sw = brightness(at(texCoord + pixel * vec2(-1.0, 1.0)));
    float se = brightness(at(texCoord + pixel * vec2(1.0, 1.0)));
    float lowest = min(m, min(min(nw, ne), min(sw, se)));
    float highest = max(m, max(max(nw, ne), max(sw, se)));

    // Too little difference to see steps in, more so where the picture is bright.
    if (highest - lowest < max(0.03, highest * 0.12)) {
        return middle;
    }

    // The edge runs at right angles to the way brightness changes. The steeper it runs towards one axis the
    // further the blend reaches along it, up to eight pixels.
    vec2 along = vec2((sw + se) - (nw + ne), (nw + sw) - (ne + se));
    float least = max((nw + ne + sw + se) * 0.03125, 0.0078125);
    along = clamp(along / (min(abs(along.x), abs(along.y)) + least), vec2(-8.0), vec2(8.0)) * pixel;

    vec3 near = 0.5 * (at(texCoord - along / 6.0) + at(texCoord + along / 6.0));
    vec3 wide = 0.5 * near + 0.25 * (at(texCoord - along * 0.5) + at(texCoord + along * 0.5));
    // The wider blend is taken unless it reached past the edge into something else.
    float reached = brightness(wide);
    return reached < lowest || reached > highest ? near : wide;
}

#ifdef FXAA
// FXAA 3.11, at its quality settings: finds where brightness steps sharply, which way the edge runs, and how far
// along it the step goes before it ends, then blends across it by how near the pixel is to the step's end.
vec3 fxaa() {
    vec2 pixel = MxScreen.zw;
    vec3 middle = at(texCoord);
    float m = brightness(middle);
    float n = brightness(at(texCoord + vec2(0.0, pixel.y)));
    float s = brightness(at(texCoord - vec2(0.0, pixel.y)));
    float e = brightness(at(texCoord + vec2(pixel.x, 0.0)));
    float w = brightness(at(texCoord - vec2(pixel.x, 0.0)));
    float highest = max(m, max(max(n, s), max(e, w)));
    float lowest = min(m, min(min(n, s), min(e, w)));
    float range = highest - lowest;
    if (range < max(0.0312, highest * 0.125)) {
        return middle;
    }

    float ne = brightness(at(texCoord + pixel));
    float sw = brightness(at(texCoord - pixel));
    float nw = brightness(at(texCoord + vec2(-pixel.x, pixel.y)));
    float se = brightness(at(texCoord + vec2(pixel.x, -pixel.y)));

    // How far the pixel is from being a stray dot, for the blend across at the end.
    float around = (2.0 * (n + s + e + w) + ne + nw + se + sw) / 12.0;
    float dot_blend = clamp(abs(around - m) / range, 0.0, 1.0);
    dot_blend = smoothstep(0.0, 1.0, dot_blend);
    dot_blend = dot_blend * dot_blend * 0.75;

    float across_x = abs(nw + sw - 2.0 * w) + 2.0 * abs(n + s - 2.0 * m) + abs(ne + se - 2.0 * e);
    float across_y = abs(nw + ne - 2.0 * n) + 2.0 * abs(w + e - 2.0 * m) + abs(sw + se - 2.0 * s);
    bool horizontal = across_y >= across_x;

    // The side of the step the pixel faces: which neighbour across the edge differs most.
    float step_length = horizontal ? pixel.y : pixel.x;
    float before = horizontal ? s : w;
    float after = horizontal ? n : e;
    float gradient_before = abs(before - m);
    float gradient_after = abs(after - m);
    bool steeper_before = gradient_before >= gradient_after;
    float gradient = 0.25 * max(gradient_before, gradient_after);
    float edge_luma;
    if (steeper_before) {
        step_length = -step_length;
        edge_luma = 0.5 * (before + m);
    } else {
        edge_luma = 0.5 * (after + m);
    }

    // Along the edge in both directions until the brightness no longer matches it.
    vec2 uv = texCoord;
    vec2 along = horizontal ? vec2(pixel.x, 0.0) : vec2(0.0, pixel.y);
    if (horizontal) {
        uv.y += step_length * 0.5;
    } else {
        uv.x += step_length * 0.5;
    }
    const float STEPS[10] = float[10](1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 4.0, 8.0, 8.0, 8.0);
    vec2 uv1 = uv - along;
    vec2 uv2 = uv + along;
    float end1 = brightness(at(uv1)) - edge_luma;
    float end2 = brightness(at(uv2)) - edge_luma;
    bool done1 = abs(end1) >= gradient;
    bool done2 = abs(end2) >= gradient;
    for (int i = 1; i < 10 && !(done1 && done2); i++) {
        if (!done1) {
            uv1 -= along * STEPS[i];
            end1 = brightness(at(uv1)) - edge_luma;
            done1 = abs(end1) >= gradient;
        }
        if (!done2) {
            uv2 += along * STEPS[i];
            end2 = brightness(at(uv2)) - edge_luma;
            done2 = abs(end2) >= gradient;
        }
    }

    float distance1 = horizontal ? texCoord.x - uv1.x : texCoord.y - uv1.y;
    float distance2 = horizontal ? uv2.x - texCoord.x : uv2.y - texCoord.y;
    bool nearer1 = distance1 < distance2;
    float nearest = min(distance1, distance2);
    float span = distance1 + distance2;
    // Blended only where the step's end lies the other way from the pixel's own side of it.
    bool centre_lower = m - edge_luma < 0.0;
    bool right_way = ((nearer1 ? end1 : end2) < 0.0) != centre_lower;
    float edge_blend = right_way ? 0.5 - nearest / span : 0.0;

    float offset = max(edge_blend, dot_blend);
    vec2 final_uv = texCoord;
    if (horizontal) {
        final_uv.y += offset * step_length;
    } else {
        final_uv.x += offset * step_length;
    }
    return at(final_uv);
}
#endif

#if SHARPENING > 0
// AMD's contrast adaptive sharpening on `middle`, from the pixels around it: each pushed away from the cross of
// its four neighbours, by less where those already span a wide range, so edges do not ring and noise is not
// lifted.
vec3 sharpened(vec3 middle) {
    ivec2 texel = ivec2(gl_FragCoord.xy);
    ivec2 last = ivec2(MxScreen.xy) - 1;
    vec3 a = texelFetch(colortex0, clamp(texel + ivec2(-1, 1), ivec2(0), last), 0).rgb;
    vec3 b = texelFetch(colortex0, clamp(texel + ivec2(0, 1), ivec2(0), last), 0).rgb;
    vec3 c = texelFetch(colortex0, clamp(texel + ivec2(1, 1), ivec2(0), last), 0).rgb;
    vec3 d = texelFetch(colortex0, clamp(texel + ivec2(-1, 0), ivec2(0), last), 0).rgb;
    vec3 f = texelFetch(colortex0, clamp(texel + ivec2(1, 0), ivec2(0), last), 0).rgb;
    vec3 g = texelFetch(colortex0, clamp(texel + ivec2(-1, -1), ivec2(0), last), 0).rgb;
    vec3 h = texelFetch(colortex0, clamp(texel + ivec2(0, -1), ivec2(0), last), 0).rgb;
    vec3 i = texelFetch(colortex0, clamp(texel + ivec2(1, -1), ivec2(0), last), 0).rgb;
    vec3 e = middle;

    vec3 lowest = min(min(min(d, e), min(f, b)), h);
    lowest += min(lowest, min(min(a, c), min(g, i)));
    vec3 highest = max(max(max(d, e), max(f, b)), h);
    highest += max(highest, max(max(a, c), max(g, i)));
    vec3 amount = sqrt(clamp(min(lowest, 2.0 - highest) / max(highest, vec3(1.0e-4)), 0.0, 1.0));
    vec3 weight = amount * (-1.0 / mix(8.0, 5.0, float(SHARPENING) / 100.0));
    return clamp(((b + d + f + h) * weight + e) / (1.0 + 4.0 * weight), 0.0, 1.0);
}
#endif

#ifdef BLOOM
// The blurred light, rolled off again the way bloom_prefilter.fsh undid it, laid over the picture as a thin
// layer. Each pixel becomes mostly itself and a little of the light around it; where the picture is even that
// changes nothing, next to something bright the brightness spills over.
vec3 glow(vec3 color) {
    if (MxBloom <= 0.0) {
        return color;
    }
    // Four sizes were added together on the way up.
    vec3 light = texture(colortex10, texCoord).rgb * 0.25;
    float level = max(light.r, max(light.g, light.b));
    vec3 shown = light * ((1.0 - exp(-level)) / max(level, 1.0e-4));
    float share = 0.18 * MxBloom;
    return mx_to_display(shown) * share + color * (1.0 - share);
}
#endif

void main() {
    mx_setup();
#ifdef FXAA
    vec3 color = fxaa();
#else
    vec3 color = at(texCoord);
#ifdef SMOOTH_EDGES
    color = smoothed(color);
#endif
#endif
#if SHARPENING > 0
    color = sharpened(color);
#endif
#ifdef BLOOM
    color = glow(color);
#endif
#ifdef MX_GRADING
    color = mx_color_grade(color, texCoord);
#endif
    fragColor = vec4(color, 1.0);
}
