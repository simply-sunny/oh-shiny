// What keeps the game's own look. MX_TEXTURED: has a texture. MX_LIGHTMAP: lit by the game's light map.
// MX_GAME_FOG: fades into the game's fog.

#include "/lib/frame.glsl"

#ifdef MX_TEXTURED
uniform sampler2D gtexture;
#endif
#ifdef MX_LIGHTMAP
uniform sampler2D lightmap;
#endif

in vec4 v_Color;
in vec2 v_TexCoord;
in vec2 v_LightMap;
in vec3 v_Position;

layout(location = 0) out vec4 fragColor;

void main() {
    mx_setup();
    vec4 color = v_Color;
#ifdef MX_TEXTURED
    color *= texture(gtexture, v_TexCoord);
#endif
    if (color.a < 0.004) {
        discard;
    }
#ifdef MX_LIGHTMAP
    color *= texture(lightmap, v_LightMap);
#endif
#ifdef MX_GAME_FOG
    float distance_to = length(v_Position);
    float amount = 0.0;
    if (fogEnd > fogStart) {
        amount = clamp((distance_to - fogStart) / (fogEnd - fogStart), 0.0, 1.0);
    }
    color.rgb = mix(color.rgb, fogColor, amount);
#endif
    fragColor = color;
}
