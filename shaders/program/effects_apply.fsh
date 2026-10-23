// Lays the effects over the picture: occlusion darkens, sun rays add light.

#include "/lib/frame.glsl"
#include "/lib/color.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex7;

in vec2 texCoord;

layout(location = 0) out vec4 fragColor;

void main() {
    mx_setup();
    vec3 color = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0).rgb;
#if defined AMBIENT_OCCLUSION || defined SUN_RAYS
    vec4 effects = textureLod(colortex7, texCoord, 0.0);
    vec3 linear = mx_to_linear(color) * effects.a;
    vec3 rays = 1.0 - exp(-effects.rgb * MxExposure);
    // Rays are screen-blended, so they brighten without clipping; in linear light, so they lift what is dark
    // by no more than they add to what is bright.
    color = mx_to_display(linear + rays * (1.0 - linear));
#endif
    fragColor = vec4(color, 1.0);
}
