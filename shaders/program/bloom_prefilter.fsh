// The first step of the glow: the picture at half size, with its light as bright as it was. The glow is a chain:
// this, four steps down to 1/32 (bloom_downsample.fsh), four steps back up with each size added onto the one
// above it (bloom_upsample.fsh), then a thin layer over the picture (bloom_composite.fsh). The blur that gives is
// tight near a bright thing and wide further out.

#include "/lib/frame.glsl"
#include "/lib/color.glsl"

uniform sampler2D colortex0;

in vec2 texCoord;

layout(location = 0) out vec4 fragColor;

// The picture holds light after it has been rolled off towards white (see color.glsl), so in it the sun is no
// brighter than a white wall. Undoing the roll-off gives back how bright each thing was: the sun, lava and a
// torch flame then far outweigh what is around them when the image is blurred, and it is they that glow.
vec3 scene_light(vec2 uv) {
    vec3 shown = mx_to_linear(texture(colortex0, uv).rgb);
    float level = max(shown.r, max(shown.g, shown.b));
    return shown * (-log(1.0 - min(level, 0.996)) / max(level, 1.0e-4));
}

// Four spread samples per pixel, each weighted down by its own brightness, so a single very bright pixel does
// not flicker as the camera moves.
void main() {
    mx_setup();
    if (MxBloom <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }
    vec2 texel = 1.0 / vec2(textureSize(colortex0, 0));
    vec3 a = scene_light(texCoord + texel * vec2(-1.0, -1.0));
    vec3 b = scene_light(texCoord + texel * vec2(1.0, -1.0));
    vec3 c = scene_light(texCoord + texel * vec2(-1.0, 1.0));
    vec3 d = scene_light(texCoord + texel * vec2(1.0, 1.0));
    float wa = 1.0 / (1.0 + mx_luminance(a));
    float wb = 1.0 / (1.0 + mx_luminance(b));
    float wc = 1.0 / (1.0 + mx_luminance(c));
    float wd = 1.0 / (1.0 + mx_luminance(d));
    fragColor = vec4((a * wa + b * wb + c * wc + d * wd) / (wa + wb + wc + wd), 1.0);
}
