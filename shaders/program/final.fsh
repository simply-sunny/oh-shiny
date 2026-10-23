// The picture to the screen. With Smooth Edges on, the stair steps along edges are smoothed, only where
// the depth says one thing ends and another begins, or a surface turns a corner: the texels of a block's own
// texture are edges too, to the eye of a filter, and blending those would blur every block.

#include "/lib/frame.glsl"

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

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

void main() {
    mx_setup();
    vec3 color = at(texCoord);
#ifdef SMOOTH_EDGES
    color = smoothed(color);
#endif
    fragColor = vec4(color, 1.0);
}
