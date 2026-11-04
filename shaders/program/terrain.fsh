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
#ifdef PBR
#include "/lib/pbr.glsl"
#endif

uniform sampler2D gtexture;

in vec4 v_Color;
in vec2 v_TexCoord;
in vec2 v_Light;
in vec3 v_Position;
in vec3 v_Normal;
in vec3 v_ShadowUnbent;
flat in int v_Type;
#ifdef POM
flat in vec2 v_TexMid;
flat in vec2 v_TexHalf;
#endif

layout(location = 0) out vec4 fragColor;

void main() {
    mx_setup();
    // Sodium's mesh had no normals for the original. Every face is flat, so the normal is the direction the
    // surface position does not change in from one pixel to the next.
    vec3 normal = normalize(cross(dFdx(v_Position), dFdy(v_Position)));
    // Turned to face the camera, for faces seen from behind (plants, the underside of water).
    if (dot(normal, v_Position) > 0.0) {
        normal = -normal;
    }
    int type = v_Type;

    // With a resource pack's normal and specular maps (pbr.glsl), the face's texture coordinates may first be moved
    // to where the line of sight meets the height map. Plants and leaves are left flat: their faces are not solid.
    vec2 uv = v_TexCoord;
#ifdef PBR
    vec2 uv_dx = dFdx(v_TexCoord);
    vec2 uv_dy = dFdy(v_TexCoord);
    MxFrame frame = mx_tangent_frame(v_Position, v_TexCoord, normal);
#if defined POM && !defined MX_TRANSLUCENT
    if (!mx_is_plant(type) && type != MX_BLOCK_LEAVES && type != MX_BLOCK_GLOW_BERRIES) {
        uv = mx_pom(uv, uv_dx, uv_dy, v_Position, frame, v_TexMid, v_TexHalf);
    }
#endif
    vec4 texel = textureGrad(gtexture, uv, uv_dx, uv_dy);
#else
    vec4 texel = texture(gtexture, uv);
#endif
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
    if (type == MX_BLOCK_LEAVES || type == MX_BLOCK_GLOW_BERRIES) {
        wrap = 0.3;
        ambient_scale = 0.9;
    } else if (mx_is_plant(type)) {
        wrap = 0.35;
        normal = vec3(0.0, 1.0, 0.0);
    }

    // The resource pack's bumps turn the normal that lights the surface; the face's own still decides what the shadow
    // map is asked and whether the sun can reach it at all. Light from all around feels the bumps in full, but the sun
    // and the highlights only where they are not almost edge-on to the face, and not far off: there the maps' fine
    // detail is smaller than a pixel and shimmers as the camera moves.
    vec3 shade_normal = normal;
    vec3 sun_normal = normal;
    float facing_face = mx_facing(normal, wrap);
#ifdef PBR
    MxMaterial material = mx_material(uv, uv_dx, uv_dy, frame, normal, !mx_is_plant(type));
    shade_normal = material.normal;
    sun_normal = normalize(mix(normal, shade_normal,
                               smoothstep(0.0, 0.3, facing_face) * (1.0 - smoothstep(24.0, 64.0, length(v_Position)))));
#endif

    vec3 albedo = mx_to_linear(color.rgb);
    float facing = min(mx_facing(sun_normal, wrap), clamp(facing_face * 3.0, 0.0, 1.0));
    float shadow = facing > 0.0 ? mx_shadow_from(v_Position, v_ShadowUnbent, normal) : 1.0;
    float caustic = mx_caustic_at(v_Position);
    if (mx_is_sea_plant(type)) {
        // Light under water comes from everywhere and through the blades, so one blade only shades the next a
        // little; in full, the plant's lower half was cut off nearly black. Caustics follow the ground: on an
        // upright blade, which stays at one place on it all the way up, they were neon stripes.
        shadow = mix(0.55, 1.0, shadow);
        caustic = mix(1.0, caustic, 0.2);
    }

    // How much a surface mirrors the sun: polished things and metal a lot, most blocks a little. Rain wets
    // everything under the open sky, which darkens it and makes it shine.
    float gloss = 0.08;
    vec3 highlight = vec3(1.0);
    if (type == MX_BLOCK_SHINY) {
        gloss = 0.55;
    } else if (type == MX_BLOCK_METAL) {
        gloss = 0.8;
        highlight = albedo / max(mx_luminance(albedo), 0.05);
    } else if (type == MX_BLOCK_LEAVES || type == MX_BLOCK_GLOW_BERRIES || mx_is_plant(type)) {
        gloss = 0.0;
    }
    float wet = MxSkyAmbient.w * smoothstep(0.75, 1.0, v_Light.y) * (MxSkyHorizon.w < 0.5 ? 1.0 : 0.0);
    if (type != MX_BLOCK_LAVA) {
        gloss = max(gloss, 0.5 * wet);
        albedo *= 1.0 - 0.3 * wet;
    }

    // A resource pack's specular map replaces the guesses above where it has one, except for plants and leaves, which
    // stay matte. Metal takes its color from the texture and has little diffuse light of its own.
    float occlusion = 1.0;
    vec3 diffuse = albedo;
    vec3 shine = vec3(0.0);
    bool pack_shine = false;
#ifdef PBR
    occlusion = material.occlusion;
    pack_shine = material.has_specular && type != MX_BLOCK_LAVA && type != MX_BLOCK_LEAVES
              && type != MX_BLOCK_GLOW_BERRIES && !mx_is_plant(type);
    if (pack_shine) {
        float smoothness = max(material.smoothness, 0.5 * wet);
        vec3 f0 = material.metal ? clamp(albedo, 0.0, 1.0) : vec3(material.f0);
        if (material.metal) {
            diffuse = albedo * 0.25;
        }
        // The sun's highlight dies away as the sun goes edge-on to the face: on rough surfaces it was a sparkling sheen.
        shine = mx_specular_pbr(sun_normal, v_Position, smoothness, f0, shadow, v_Light) * clamp(facing_face * 4.0, 0.0, 1.0)
              + mx_reflection_pbr(sun_normal, v_Position, smoothness, f0, v_Light);
    }
#endif

    vec3 lit = mx_lit(diffuse, shade_normal, v_Position, v_Light, facing, shadow, caustic, occlusion) * ambient_scale;
    lit += pack_shine ? shine : mx_specular(sun_normal, v_Position, gloss, highlight, shadow, v_Light);

    // Light comes through leaves and plants: seen against the sun they glow with it instead of going black.
    if (wrap > 0.0) {
        float against = pow(max(dot(normalize(v_Position), MxLightDir.xyz), 0.0), 6.0);
        if (against > 0.01) {
            float reached = facing > 0.0 ? shadow : mx_shadow_from(v_Position, v_ShadowUnbent, normal);
            lit += albedo * MxLightColor.rgb * against * 0.45 * reached * smoothstep(0.08, 0.5, v_Light.y);
        }
    }

    // Blocks that give off light show it themselves, more the brighter they are; lava most of all. A resource pack's
    // emission map glows as it says, and where the pack has none the block's own glow below still stands.
    float glow = 0.0;
#ifdef PBR
    glow = material.emissive * 3.0;
#endif
    if (type == MX_BLOCK_LAVA) {
        lit = albedo * 4.5;
    } else if (type == MX_BLOCK_GLOWING) {
        float level = v_Light.x;
        glow = max(glow, level * level * 3.0);
    } else if (type == MX_BLOCK_GLOW_BERRIES) {
        // Only the berries glow: the bright orange in the texture, not the leaves around them.
        float berry = smoothstep(0.15, 0.35, color.r - color.b) * smoothstep(0.55, 0.75, color.r);
        float level = v_Light.x;
        glow = max(glow, level * level * 3.0 * berry);
    } else if (type == MX_BLOCK_GLOW_SPECKS) {
        // Only the specks glow: the strongly colored texels, not the grey stone between them, which glowing
        // along with them turned the whole block a flat white. A speck's paler rim glows less than its middle, so
        // each fades into the stone instead of ending in a hard edge.
        float chroma = max(color.r, max(color.g, color.b)) - min(color.r, min(color.g, color.b));
        float speck = smoothstep(0.15, 0.45, chroma);
        float level = v_Light.x;
        glow = max(glow, level * level * 3.0 * speck);
    }
    lit += albedo * glow;

    fragColor = vec4(mx_fogged(lit, v_Position, fog), color.a);
}
