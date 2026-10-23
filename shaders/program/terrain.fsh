// Terrain: solid and cut-out blocks (gbuffers_terrain), and with MX_TRANSLUCENT water, glass and the like
// (gbuffers_water).

#include "/lib/frame.glsl"
#include "/lib/color.glsl"
#include "/lib/noise.glsl"
#include "/lib/sky.glsl"
#include "/lib/shadow.glsl"
#include "/lib/lighting.glsl"
#include "/lib/fog.glsl"
#include "/lib/block_ids.glsl"
#ifdef MX_TRANSLUCENT
#include "/lib/water.glsl"
#endif

uniform sampler2D gtexture;

in vec4 v_Color;
in vec2 v_TexCoord;
in vec2 v_Light;
in vec3 v_Position;
in vec3 v_Normal;
flat in int v_Type;

layout(location = 0) out vec4 fragColor;

void main() {
    mx_setup();
    vec4 texel = texture(gtexture, v_TexCoord);
    vec4 color = texel * v_Color;
#ifdef MX_TRANSLUCENT
    if (color.a < 0.004) {
        discard;
    }
#else
    if (color.a < 0.1) {
        discard;
    }
#endif

    // Sodium's mesh had no normals for the original. Every face is flat, so the normal is the direction the
    // surface position does not change in from one pixel to the next.
    vec3 normal = normalize(cross(dFdx(v_Position), dFdy(v_Position)));
    // Turned to face the camera, for faces seen from behind (plants, the underside of water).
    if (dot(normal, v_Position) > 0.0) {
        normal = -normal;
    }

    int type = v_Type;
    float fog = mx_fog_amount(v_Position);

#ifdef MX_TRANSLUCENT
    if (type == MX_BLOCK_WATER) {
        // The water texture's light and dark texels are kept only as a faint pattern.
        vec3 water_color = v_Color.rgb * mix(1.0, texel.r + 0.35, 0.3);
        if (MxUnderwater) {
            fragColor = mx_water_below(water_color, v_Position, normal, v_Light);
            return;
        }
        if (MxSkyHorizon.w < 0.5) {
            fragColor = mx_water(water_color, v_Position, normal, v_Light, fog);
            return;
        }
        // Under a closed sky (the Nether, blindness) water is lit like glass, below.
    }
#endif

    // Leaves and plants are thin: light comes through them, so their shaded side is not fully dark. A plant's
    // crossed quads have no meaningful facing of their own and are lit like the ground they grow from.
    float wrap = 0.0;
    float ambient_scale = 1.0;
    if (type == MX_BLOCK_LEAVES) {
        wrap = 0.3;
        ambient_scale = 0.9;
    } else if (mx_is_plant(type)) {
        wrap = 0.35;
        normal = vec3(0.0, 1.0, 0.0);
    }

    vec3 albedo = mx_to_linear(color.rgb);
    float facing = mx_facing(normal, wrap);
    float shadow = facing > 0.0 ? mx_shadow(v_Position, normal) : 1.0;

    // How much a surface mirrors the sun: polished things and metal a lot, most blocks a little. Rain wets
    // everything under the open sky, which darkens it and makes it shine.
    float gloss = 0.08;
    vec3 highlight = vec3(1.0);
    if (type == MX_BLOCK_SHINY) {
        gloss = 0.55;
    } else if (type == MX_BLOCK_METAL) {
        gloss = 0.8;
        highlight = albedo / max(mx_luminance(albedo), 0.05);
    } else if (type == MX_BLOCK_LEAVES || mx_is_plant(type)) {
        gloss = 0.0;
    }
    float wet = MxSkyAmbient.w * smoothstep(0.75, 1.0, v_Light.y) * (MxSkyHorizon.w < 0.5 ? 1.0 : 0.0);
    if (type != MX_BLOCK_LAVA) {
        gloss = max(gloss, 0.5 * wet);
        albedo *= 1.0 - 0.3 * wet;
    }

    vec3 lit = mx_lit(albedo, normal, v_Position, v_Light, facing, shadow) * ambient_scale;
    lit += mx_specular(normal, v_Position, gloss, highlight, shadow, v_Light);

    // Light comes through leaves and plants: seen against the sun they glow with it instead of going black.
    if (wrap > 0.0) {
        float against = pow(max(dot(normalize(v_Position), MxLightDir.xyz), 0.0), 6.0);
        if (against > 0.01) {
            float reached = facing > 0.0 ? shadow : mx_shadow(v_Position, normal);
            lit += albedo * MxLightColor.rgb * against * 0.45 * reached * smoothstep(0.08, 0.5, v_Light.y);
        }
    }

    // Blocks that give off light show it themselves, more the brighter they are; lava most of all.
    if (type == MX_BLOCK_LAVA) {
        lit = albedo * 4.5;
    } else if (type == MX_BLOCK_GLOWING) {
        float level = v_Light.x;
        lit += albedo * level * level * 3.0;
    }

    fragColor = vec4(mx_fogged(lit, v_Position, fog), color.a);
}
