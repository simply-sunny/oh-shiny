// How far-off terrain from Distant Horizons (program/lod.fsh) and Voxy (voxy_opaque.glsl, voxy_translucent.glsl)
// is shaded. It is lit like the near terrain, but without shadows (the shadow map does not reach that far) or
// the map of light colors (it only covers the ground around the player). Programs define MX_LOD_PASS before
// including this.
#ifndef MX_LOD_SHADING
#define MX_LOD_SHADING

#include "/lib/frame.glsl"
#include "/lib/color.glsl"
#include "/lib/sky.glsl"
#include "/lib/lighting.glsl"
#include "/lib/fog.glsl"
#include "/lib/block_ids.glsl"

// Far-off water: no bottom shows through it from that far, so it is the deep water's own color and the sky it
// mirrors, with the sun's glint, and only a little of what is behind it.
vec4 mx_lod_water(vec3 tint, vec3 position, vec2 light, float fog) {
    vec3 view = normalize(position);
    vec3 normal = vec3(0.0, 1.0, 0.0);
    vec3 scatter = mx_lit(mx_to_linear(tint), normal, position, light, mx_facing(normal, 0.0), 1.0);
    vec3 body = mx_tonemap(scatter * 0.12 * MxExposure);

    float cosine = clamp(-view.y, 0.0, 1.0);
    float mirror = 0.14 + 0.86 * pow(1.0 - cosine, 2.2);
    vec3 mirrored = reflect(view, normal);
    mirrored.y = max(mirrored.y, 0.02);
    mirrored = normalize(mirrored);
    float towards_light = max(dot(mirrored, MxLightDir.xyz), 0.0);
    vec3 sky = mx_sky(mirrored) + MxLightColor.rgb * pow(towards_light, 80.0) * 0.7 * MxLightDir.w;
    vec3 reflection = mx_tonemap(sky * MxExposure) * smoothstep(0.1, 0.9, light.y);

    vec3 over = mix(body, reflection, mirror);
    float alpha = 1.0 - 0.2 * (1.0 - mirror);
    if (MxSkyHorizon.w > 0.5) {
        return vec4(mix(mx_to_display(mx_grade(over)), fogColor, fog), mix(alpha, 1.0, fog));
    }
    float amount = mx_fog_total(position, fog);
    over = mix(over, mx_tonemap(mx_fog_sky(view) * MxExposure), amount);
    return vec4(mx_to_display(mx_grade(over)), mix(alpha, 1.0, amount));
}

// `color`: the block's color as the mod gives it (a display color, tinted). `position`: relative to the eye.
// `normal`: world orientation. `light`: block light and sky light, 0..1. `type`: as mx_block_type gives it.
// Returns the display color to write, fogged, and its alpha.
vec4 mx_lod_color(vec4 color, vec3 position, vec3 normal, vec2 light, int type) {
    float fog = mx_fog_amount(position);
    if (type == MX_BLOCK_WATER) {
        return mx_lod_water(color.rgb, position, light, fog);
    }

    vec3 albedo = mx_to_linear(color.rgb);
    // Leaves let a little light through to their shaded side, as near ones do (terrain.fsh).
    float wrap = type == MX_BLOCK_LEAVES ? 0.3 : 0.0;
    float facing = mx_facing(normal, wrap);
    float gloss = type == MX_BLOCK_METAL ? 0.8 : (type == MX_BLOCK_LEAVES ? 0.0 : 0.08);
    float wet = MxSkyAmbient.w * smoothstep(0.75, 1.0, light.y) * (MxSkyHorizon.w < 0.5 ? 1.0 : 0.0);
    if (type != MX_BLOCK_LAVA) {
        gloss = max(gloss, 0.5 * wet);
        albedo *= 1.0 - 0.3 * wet;
    }

    vec3 lit = mx_lit(albedo, normal, position, light, facing, 1.0);
    lit += mx_specular(normal, position, gloss, type == MX_BLOCK_METAL ? albedo / max(mx_luminance(albedo), 0.05) : vec3(1.0), 1.0, light);
    if (type == MX_BLOCK_LAVA) {
        lit = albedo * 4.5;
    } else if (type == MX_BLOCK_GLOWING) {
        lit += albedo * light.x * light.x * 3.0;
    }
    return vec4(mx_fogged(lit, position, fog), color.a);
}

#endif
