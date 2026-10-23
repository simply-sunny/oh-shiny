// The game's clouds. The mesh and where it is are the game's; the light is the pack's.

#include "/lib/frame.glsl"
#include "/lib/color.glsl"
#include "/lib/sky.glsl"
#include "/lib/fog.glsl"

in vec4 v_Color;
in vec3 v_Position;

layout(location = 0) out vec4 fragColor;

void main() {
    mx_setup();
    float distance_to = length(v_Position);
    // Thinned out towards where the game stops drawing them.
    float thin = smoothstep(0.6, 1.0, distance_to / max(far * 4.0, 256.0));
    if (MxSkyHorizon.w > 0.5) {
        fragColor = vec4(v_Color.rgb, v_Color.a * (1.0 - thin));
        return;
    }

    // Clouds are boxes; each face is flat, so its normal is worked out from the surface itself.
    vec3 normal = normalize(cross(dFdx(v_Position), dFdy(v_Position)));
    if (dot(normal, v_Position) > 0.0) {
        normal = -normal;
    }
    vec3 view = v_Position / max(distance_to, 1.0e-4);

    // A cloud is a thick body of mist. Light goes round and through it, so the side turned from the sun is
    // dimmer but never dark, and its edge shines when the sun is close behind it.
    float towards = dot(normal, MxLightDir.xyz);
    float direct = 0.34 + 0.66 * clamp(towards * 0.5 + 0.5, 0.0, 1.0);
    float lining = pow(max(dot(view, MxLightDir.xyz), 0.0), 10.0);
    vec3 light = MxLightColor.rgb * (direct + 0.6 * lining)
               + MxSkyAmbient.rgb * (0.72 + 0.28 * normal.y)
               + MxMinAmbient.rgb;
    vec3 lit = vec3(0.50) * light * (1.0 - clamp(MxMinAmbient.w, 0.0, 0.85));
    // Rain clouds are a closed deck with no sunlit side: the color of the rainy sky, a shade darker.
    lit = mix(lit, MxSkyHorizon.rgb * 0.9, smoothstep(0.0, 0.7, MxSkyAmbient.w));

    // Far clouds sink into the haze of the sky behind them.
    float haze = 1.0 - exp(-distance_to * 0.0009);
    lit = mix(lit, mx_fog_sky(view), haze);

    fragColor = vec4(mx_encode(lit), v_Color.a * (1.0 - thin));
}
