// The last step of the glow: the blurred light, rolled off again the way bloom_prefilter.fsh undid it, laid
// over the picture as a thin layer. Each pixel becomes mostly itself and a little of the light around it; where
// the picture is even that changes nothing, next to something bright the brightness spills over.

#include "/lib/frame.glsl"
#include "/lib/color.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex10;

in vec2 texCoord;

layout(location = 0) out vec4 fragColor;

void main() {
    mx_setup();
    vec3 color = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0).rgb;
    if (MxBloom > 0.0) {
        // Five sizes were added together on the way up.
        vec3 light = texture(colortex10, texCoord).rgb * 0.2;
        float level = max(light.r, max(light.g, light.b));
        vec3 shown = light * ((1.0 - exp(-level)) / max(level, 1.0e-4));
        float share = 0.18 * MxBloom;
        color = mx_to_display(shown) * share + color * (1.0 - share);
    }
    fragColor = vec4(color, 1.0);
}
