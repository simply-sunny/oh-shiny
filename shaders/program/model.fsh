// Everything the game draws as a model rather than as terrain: mobs, players, block entities, dropped items,
// the hand, particles. MX_PARTICLE: faces the camera, so has no side to turn to the light. MX_EMISSIVE: gives
// off its own light (eyes, charged creepers). MX_ENTITY: tinted red when hurt. MX_HAND: the held item and arm,
// which is shaded the way the game does.

#include "/lib/frame.glsl"
#include "/lib/color.glsl"
#include "/lib/noise.glsl"
#include "/lib/sky.glsl"
#include "/lib/shadow.glsl"
#include "/lib/lighting.glsl"
#include "/lib/fog.glsl"
#include "/lib/block_ids.glsl"

uniform sampler2D gtexture;
#ifdef MX_HAND
uniform sampler2D lightmap;
#endif
#ifdef MX_ENTITY
uniform vec4 entityColor;
uniform int entityId;
#endif

in vec4 v_Color;
in vec2 v_TexCoord;
in vec2 v_Light;
in vec3 v_Position;
in vec3 v_Normal;

layout(location = 0) out vec4 fragColor;

void main() {
    mx_setup();
    vec4 color = texture(gtexture, v_TexCoord) * v_Color;
    if (color.a < 0.1) {
        discard;
    }
#ifdef MX_ENTITY
    color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
#endif
#ifdef MX_HAND
    // The game's fixed pair of lights on models: 40% everywhere plus 60% for each light a face is turned to.
    vec3 model_normal = normalize(v_Normal);
    float first = max(dot(model_normal, normalize(vec3(0.2, 1.0, -0.7))), 0.0);
    float second = max(dot(model_normal, normalize(vec3(-0.2, 1.0, 0.7))), 0.0);
    float shade = min(1.0, (first + second) * 0.6 + 0.4);
    vec2 light_map = v_Light * (15.0 / 16.0) + 1.0 / 32.0;
    fragColor = vec4(color.rgb * shade * texture(lightmap, light_map).rgb, color.a);
    return;
#endif
    vec3 albedo = mx_to_linear(color.rgb);

#ifdef MX_EMISSIVE
    vec3 lit = albedo * 1.7;
#else
#ifdef MX_PARTICLE
    // Light it as if it faced halfway between straight up and the sun.
    vec3 normal = normalize(MxLightDir.xyz + vec3(0.0, 1.0, 0.0));
#else
    vec3 normal = v_Normal;
    if (dot(normal, normal) < 0.01) {
        normal = normalize(cross(dFdx(v_Position), dFdy(v_Position)));
    }
    normal = normalize(normal);
    if (dot(normal, v_Position) > 0.0) {
        normal = -normal;
    }
#endif
    float facing = mx_facing(normal, 0.0);
    vec3 lit = mx_lit(albedo, normal, v_Position, v_Light, facing, facing > 0.0 ? mx_shadow(v_Position, normal) : 1.0);
#endif

    fragColor = vec4(mx_fogged(lit, v_Position, mx_fog_amount(v_Position)), color.a);
}
