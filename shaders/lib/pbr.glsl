// A resource pack's normal and specular maps, in the LabPBR 1.3 layout. The normal map holds the surface normal's x and y
// in red and green, ambient occlusion in blue and height in alpha; the specular map holds smoothness in red,
// reflectance (230 and up: a metal) in green and emission in alpha (255 is none). Without such a pack Iris hands over
// flat maps with no specular, and everything is lit as it was.
#ifndef MX_PBR
#define MX_PBR

#include "/lib/frame.glsl"

uniform sampler2D normals;
uniform sampler2D specular;

// A block face's tangent frame, worked out from how its position and texture coordinates change from one pixel to the
// next: the mesh has no tangents.
struct MxFrame {
    mat3 tbn;     // columns: along texture u, up the texture (against v, as normal maps have green up), the face's normal
    vec2 per_uv;  // blocks the face spans per unit of texture u and v
    bool ok;
};

MxFrame mx_tangent_frame(vec3 position, vec2 uv, vec3 normal) {
    vec3 dp1 = dFdx(position);
    vec3 dp2 = dFdy(position);
    vec2 du1 = dFdx(uv);
    vec2 du2 = dFdy(uv);
    float det = du1.x * du2.y - du1.y * du2.x;
    MxFrame frame;
    frame.ok = abs(det) > 1.0e-16;
    vec3 along_u = frame.ok ? (dp1 * du2.y - dp2 * du1.y) / det : vec3(1.0, 0.0, 0.0);
    vec3 along_v = frame.ok ? (dp2 * du1.x - dp1 * du2.x) / det : vec3(0.0, 1.0, 0.0);
    frame.per_uv = vec2(length(along_u), length(along_v));
    frame.ok = frame.ok && min(frame.per_uv.x, frame.per_uv.y) > 1.0e-6;
    vec3 t = normalize(along_u - normal * dot(normal, along_u));
    vec3 b = normalize(-(along_v - normal * dot(normal, along_v)));
    frame.tbn = mat3(t, b, normal);
    return frame;
}

#ifdef POM
#if POM_QUALITY >= 3
const int MX_POM_STEPS = 32;
#elif POM_QUALITY == 2
const int MX_POM_STEPS = 16;
#else
const int MX_POM_STEPS = 8;
#endif

// Parallax occlusion mapping: where the line of sight meets the surface the height map describes, as the texture
// coordinates to read instead of the face's own. The surface sits up to POM_DEPTH below the face and the line is
// followed down in layers until it passes under the height there. Fades out with distance, and wraps inside the
// face's own tile of the atlas. `mid` and `half_size` are the tile's centre and half width in the atlas.
vec2 mx_pom(vec2 uv, vec2 uv_dx, vec2 uv_dy, vec3 position, MxFrame frame, vec2 mid, vec2 half_size) {
    float distance_to = length(position);
    float fade = 1.0 - smoothstep(0.6 * float(POM_DISTANCE), float(POM_DISTANCE), distance_to);
    vec3 view = (-position / max(distance_to, 1.0e-4)) * frame.tbn;
    vec2 size = 2.0 * half_size;
    // No tile data (the attribute missing) or a tile too big to be a block's: nothing to march in.
    if (!frame.ok || fade <= 0.0 || view.z < 0.08 || size.x <= 0.0 || size.y <= 0.0 || size.x > 0.25 || size.y > 0.25) {
        return uv;
    }
    vec2 low = mid - half_size;
    // Seen almost edge-on the line of sight crosses many texels for little depth and the result swims: less depth
    // there, none at all by the time it is a grazing view.
    float depth = float(POM_DEPTH) * 0.01 * 0.25 * fade * smoothstep(0.08, 0.35, view.z);
    // How far the texture coordinates move over the whole depth, as the line of sight goes down into the face.
    vec2 shift = vec2(-view.x / frame.per_uv.x, view.y / frame.per_uv.y) / view.z * depth;
    const float LAYER = 1.0 / float(MX_POM_STEPS);
    float at = 0.0;
    float under = 1.0 - textureGrad(normals, uv, uv_dx, uv_dy).a;
    vec2 before = uv;
    float gap = under;
    vec2 here = uv;
    for (int i = 0; i < MX_POM_STEPS; i++) {
        if (at >= under) {
            break;
        }
        before = here;
        gap = under - at;
        at += LAYER;
        here = uv + shift * at;
        vec2 wrapped = low + mod(here - low, size);
        under = 1.0 - textureGrad(normals, wrapped, uv_dx, uv_dy).a;
    }
    // Between the last two layers, where the line crossed the surface.
    float across = gap / max(gap + (at - under), 1.0e-4);
    vec2 hit = mix(before, here, clamp(across, 0.0, 1.0));
    return low + mod(hit - low, size);
}
#endif

struct MxMaterial {
    vec3 normal;         // world orientation
    float occlusion;     // 1 open, lower in the pack's crevices
    float smoothness;    // 0 rough, 1 mirror-like
    float f0;            // how much a non-metal mirrors head-on
    bool metal;          // reflects in its own color
    float emissive;      // 0..1
    bool has_specular;   // whether the pack has a specular map for this texture
};

MxMaterial mx_material(vec2 uv, vec2 uv_dx, vec2 uv_dy, MxFrame frame, vec3 geometric, bool bump) {
    vec4 n = textureGrad(normals, uv, uv_dx, uv_dy);
    vec4 s = textureGrad(specular, uv, uv_dx, uv_dy);
    MxMaterial material;
    material.normal = geometric;
    material.occlusion = 1.0;
    // Where there is no normal map at all Iris gives nothing here: those pixels keep the face's own normal.
    if (n.a > 0.004 || n.b > 0.004) {
        if (bump && frame.ok) {
            vec2 xy = n.rg * 2.0 - 1.0;
            vec3 tangent_space = vec3(xy, sqrt(max(1.0 - dot(xy, xy), 0.0)));
            material.normal = normalize(frame.tbn * tangent_space);
        }
        material.occlusion = n.b;
    }
    material.has_specular = s.r + s.g + s.b + s.a > 0.0;
    material.smoothness = s.r;
    material.metal = s.g * 255.0 >= 229.5;
    material.f0 = material.metal ? 0.0 : s.g;
    material.emissive = s.a * 255.0 >= 254.5 ? 0.0 : s.a * 255.0 / 254.0;
    return material;
}

#endif
