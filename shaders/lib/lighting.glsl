// How a surface is lit.
#ifndef MX_LIGHTING
#define MX_LIGHTING

#include "/lib/frame.glsl"
#include "/lib/color.glsl"
#include "/lib/noise.glsl"
#include "/lib/light_colors.glsl"
#include "/lib/block_ids.glsl"

// The game's own response of light level (0..1) to brightness: gentle at first, steep near the top.
float mx_light_curve(float level) {
    level = clamp(level, 0.0, 1.0);
    return level / (4.0 - 3.0 * level);
}

// How much a surface is turned to the light, 0..1. `wrap` above zero lets light reach a little way round to the
// far side, which is how leaves and grass look, being thin enough for light to pass through.
float mx_facing(vec3 normal, float wrap) {
    return clamp((dot(normal, MxLightDir.xyz) + wrap) / (1.0 + wrap), 0.0, 1.0);
}

// Sunlight that has come through a water surface: the ripples gather it into moving bright lines.
float mx_caustic(vec2 world, float time) {
    float a = mx_noise(world * 1.7 + vec2(time * 0.45, time * 0.30));
    float b = mx_noise(world * 2.9 - vec2(time * 0.55, -time * 0.40));
    float lines = pow(1.0 - abs(a - b), 6.0);
    return 0.55 + 1.9 * lines;
}

// Torchlight, the color of block light unless something says otherwise, as linear light at full strength.
const vec3 MX_WARM_LIGHT = vec3(1.0, 0.46, 0.15);

// A light's linear color, as bright as torchlight.
vec3 mx_light_tint(vec3 linear) {
    return linear * (mx_luminance(MX_WARM_LIGHT) / max(mx_luminance(linear), 1.0e-3));
}

// The color of the block light reaching `position` (relative to the eye), as linear light at full strength.
// Warm torchlight unless the map of light sources says the light nearby comes from something else.
vec3 mx_block_light_color(vec3 position) {
    // Far-off terrain (lod_shading.glsl) is lit without the map of light colors: it only covers the ground around
    // the player.
#if defined COLORED_LIGHT && !defined MX_LOD_PASS
    vec4 nearby = mx_light_color_at(position);
    return mix(MX_WARM_LIGHT, mx_light_tint(nearby.rgb), clamp(nearby.a, 0.0, 1.0));
#else
    return MX_WARM_LIGHT;
#endif
}

#if defined HAND_LIGHT && !defined MX_LOD_PASS
// The color of a light held in the hand: item.properties gives light-giving items the ids block.properties gives
// the blocks, 10100 + their place in mx_light_palette.
vec3 mx_held_light_color(int item) {
#ifdef COLORED_LIGHT
    int index = item - 10100;
    if (index >= 1 && index <= 8) {
        return mx_light_tint(mx_linear(mx_light_palette(index)));
    }
#endif
    return MX_WARM_LIGHT;
}

// Light from what the player holds in either hand. Iris says how bright it would be placed (0..15); it reaches
// out from the player a level less each block, as the game's own light does, through walls too, as the game
// cannot say where they are. rgb: its color, as mx_block_light_color. a: its level at `position`, 0..1.
vec4 mx_hand_light(vec3 position) {
    float reach = length(position);
    float main_hand = clamp((float(heldBlockLightValue) - reach) / 15.0, 0.0, 1.0);
    float off_hand = clamp((float(heldBlockLightValue2) - reach) / 15.0, 0.0, 1.0);
    if (main_hand >= off_hand) {
        return vec4(mx_held_light_color(heldItemId), main_hand);
    }
    return vec4(mx_held_light_color(heldItemId2), off_hand);
}
#endif

// How the ripples overhead change the sunlight at a point: seen from under water, sunlight arrives through the
// surface.
float mx_caustic_at(vec3 position) {
    return MxUnderwater ? mx_caustic((position + MxCameraPos.xyz).xz, MxCameraPos.w) : 1.0;
}

// `albedo`: linear surface color. `normal`: world orientation. `position`: relative to the eye. `light`: block
// light and sky light, each 0..1. `facing`: from mx_facing. `shadow`: 1 where the sun or moon reaches, 0 where
// something is in the way. `caustic`: from mx_caustic_at. `occlusion`: 1 open, lower where a resource pack's ambient
// occlusion map darkens the light from all around, not the sun's.
vec3 mx_lit(vec3 albedo, vec3 normal, vec3 position, vec2 light, float facing, float shadow, float caustic, float occlusion) {
    // Sky light falls off more gently than the game's curve alone, or shade under trees and shallow water
    // would be far darker than the open ground beside it.
    float sky = mix(mx_light_curve(light.y), light.y * light.y, 0.5);
    float block_level = light.x;
    vec3 block_color = mx_block_light_color(position);
#if defined HAND_LIGHT && !defined MX_LOD_PASS
    // Where a held light and the world's both reach, the stronger sets how bright it is, and their colors mix
    // by how strong each is.
    vec4 hand = mx_hand_light(position);
    if (hand.a > 0.0) {
        block_color = (block_color * block_level + hand.rgb * hand.a) / (block_level + hand.a);
        block_level = max(block_level, hand.a);
    }
#endif
    float block = mx_light_curve(block_level);

    // Direct light. Where no sky light reaches at all (deep caves) there is none, whatever the shadow map says:
    // the map only covers the ground near the player and cannot know about a mountain far overhead.
    float open = smoothstep(0.08, 0.5, light.y);
    vec3 direct = MxLightColor.rgb * facing * shadow * open * caustic;

    // Light that comes from all around has no direction to tell a block's sides apart by: with the sun
    // straight overhead, or by torchlight in a cave, every wall would be the same flat tone. So the sides
    // facing east and west are a little darker than those facing north and south, as in the game itself.
    float side = 1.0 - 0.14 * normal.x * normal.x - 0.04 * normal.z * normal.z;

    // Light from the whole sky, a little stronger on faces that look up, plus a faint warm fill bounced off
    // sunlit ground onto faces that look down or sideways.
    vec3 ambient = MxSkyAmbient.rgb * sky * (0.62 + 0.38 * normal.y) * side;
    ambient += MxLightColor.rgb * sky * 0.045 * (1.0 - 0.6 * normal.y);
    ambient *= occlusion;

    // Torches, lava and the like, in the color of whatever is giving the light, and brighter still right next
    // to the source.
    vec3 glow = block_color * 3.3 * MxBlockLight.w * block * (0.5 + 0.5 * block_level);
    glow *= side * (0.88 + 0.12 * normal.y) * mix(1.0, occlusion, 0.5);

    vec3 total = direct + ambient + glow + MxMinAmbient.rgb;
    total *= 1.0 - clamp(MxMinAmbient.w, 0.0, 0.85);
    return albedo * total;
}

vec3 mx_lit(vec3 albedo, vec3 normal, vec3 position, vec2 light, float facing, float shadow, float caustic) {
    return mx_lit(albedo, normal, position, light, facing, shadow, caustic, 1.0);
}

vec3 mx_lit(vec3 albedo, vec3 normal, vec3 position, vec2 light, float facing, float shadow) {
    return mx_lit(albedo, normal, position, light, facing, shadow, mx_caustic_at(position), 1.0);
}

// The sun's or moon's highlight on a surface. `gloss` 0 is matte, 1 a mirror-like polish. `tint` colors the
// highlight (white for most things, the surface's own color for metal).
vec3 mx_specular(vec3 normal, vec3 position, float gloss, vec3 tint, float shadow, vec2 light) {
    if (gloss <= 0.0) {
        return vec3(0.0);
    }
    vec3 to_eye = -normalize(position);
    vec3 half_way = normalize(MxLightDir.xyz + to_eye);
    float sharpness = mix(12.0, 400.0, gloss * gloss);
    float spot = pow(max(dot(normal, half_way), 0.0), sharpness) * (sharpness + 8.0) / 25.0;
    // More of the light is mirrored at a grazing angle, as on any smooth surface.
    float grazing = pow(1.0 - max(dot(normal, to_eye), 0.0), 5.0);
    float strength = mix(0.04, 1.0, grazing) * gloss;
    float open = smoothstep(0.08, 0.5, light.y);
    return MxLightColor.rgb * tint * spot * strength * shadow * open * MxLightDir.w;
}

// A resource pack's material (see pbr.glsl): the sun's or moon's highlight, as a GGX lobe with Fresnel, where
// `smoothness` sets how tight it is and `f0` (a color: a metal's own) how much is mirrored head-on.
vec3 mx_specular_pbr(vec3 normal, vec3 position, float smoothness, vec3 f0, float shadow, vec2 light) {
    vec3 to_eye = -normalize(position);
    vec3 half_way = normalize(MxLightDir.xyz + to_eye);
    float n_l = max(dot(normal, MxLightDir.xyz), 0.0);
    float n_v = max(dot(normal, to_eye), 0.01);
    float n_h = max(dot(normal, half_way), 0.0);
    float v_h = max(dot(to_eye, half_way), 0.0);
    float rough = 1.0 - smoothness;
    float alpha = max(rough * rough, 0.03);
    float alpha2 = alpha * alpha;
    float spread = n_h * n_h * (alpha2 - 1.0) + 1.0;
    float ggx = alpha2 / (3.14159265 * spread * spread);
    // Smith's shadowing of the surface's own bumps, with the light's cosine already taken out.
    float k = alpha * 0.5;
    float visible = (n_l / (n_l * (1.0 - k) + k)) * (n_v / (n_v * (1.0 - k) + k)) / (4.0 * n_v);
    vec3 fresnel = f0 + (1.0 - f0) * pow(1.0 - v_h, 5.0);
    float open = smoothstep(0.08, 0.5, light.y);
    // Rough things scatter what they catch: their highlight is dim and wide, and kept so rather than left to glint.
    float polish = mix(0.25, 1.0, smoothstep(0.25, 0.7, smoothness));
    return MxLightColor.rgb * fresnel * min(ggx * visible, 12.0) * polish * shadow * open * MxLightDir.w;
}

// The sky mirrored in a resource pack's smooth surface, more at a grazing angle, and in its own color for metal.
vec3 mx_reflection_pbr(vec3 normal, vec3 position, float smoothness, vec3 f0, vec2 light) {
    vec3 to_eye = -normalize(position);
    float n_v = max(dot(normal, to_eye), 0.0);
    vec3 fresnel = f0 + (1.0 - f0) * pow(1.0 - n_v, 5.0);
    vec3 mirrored = reflect(-to_eye, normal);
    vec3 sky = MxSkyAmbient.rgb * (0.55 + 0.45 * mirrored.y);
    return fresnel * sky * smoothness * smoothness * smoothstep(0.08, 0.5, light.y);
}

#endif
