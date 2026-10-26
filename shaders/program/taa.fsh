// Temporal anti-aliasing: this frame, drawn shifted by a fraction of a pixel (lib/taa.glsl), blended into the
// frames before it. Each pixel of the picture so far is found where it was last frame, from its depth and the
// way the camera has moved, and that earlier picture (colortex9, kept from frame to frame) is taken there.
// What was there may have been something else: a thing moved, or came out from behind another. So the earlier
// color is first pulled into the range of colors around the pixel now, which leaves it alone where the two
// agree and drops it where they do not. Writes the result both to the picture and to colortex9 for next frame.

#include "/lib/frame.glsl"
#include "/lib/taa.glsl"

/*
const int colortex9Format = RGBA16F;
*/
const bool colortex9Clear = false;

uniform sampler2D colortex0;
uniform sampler2D colortex9;
uniform sampler2D depthtex0;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform vec3 previousCameraPosition;

in vec2 texCoord;

layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 history;

// The hand is drawn with a depth range of its own, nearer than this, and moves with the camera.
const float HAND_DEPTH = 0.56;

vec3 to_ycocg(vec3 c) {
    return vec3(0.25 * c.r + 0.5 * c.g + 0.25 * c.b, 0.5 * c.r - 0.5 * c.b, -0.25 * c.r + 0.5 * c.g - 0.25 * c.b);
}

vec3 from_ycocg(vec3 c) {
    return vec3(c.x + c.y - c.z, c.x + c.z, c.x - c.y - c.z);
}

vec3 current_at(ivec2 texel) {
    return texelFetch(colortex0, clamp(texel, ivec2(0), ivec2(MxScreen.xy) - 1), 0).rgb;
}

// Where a point of the screen at `depth` was on the screen last frame. The sky is infinitely far, so only the
// turn of the camera moves it, not its steps.
vec2 last_frame_uv(vec2 uv, float depth) {
    if (depth < HAND_DEPTH) {
        return uv;
    }
    vec4 view = gbufferProjectionInverse * vec4(vec3(uv, depth) * 2.0 - 1.0, 1.0);
    view /= view.w;
    vec3 feet = (gbufferModelViewInverse * view).xyz;
    if (depth < 1.0) {
        feet += cameraPosition - previousCameraPosition;
    }
    vec4 clip = gbufferPreviousProjection * (gbufferPreviousModelView * vec4(feet, 1.0));
    return clip.xy / clip.w * 0.5 + 0.5;
}

// The earlier picture at `uv`, through a Catmull-Rom filter: a bilinear read would soften it a little more every
// frame it is carried on, this keeps it sharp. Five reads, the corners of the full sixteen left out.
vec3 history_at(vec2 uv) {
    vec2 size = MxScreen.xy;
    vec2 position = uv * size;
    vec2 centre = floor(position - 0.5) + 0.5;
    vec2 f = position - centre;
    vec2 w0 = f * (-0.5 + f * (1.0 - 0.5 * f));
    vec2 w1 = 1.0 + f * f * (-2.5 + 1.5 * f);
    vec2 w2 = f * (0.5 + f * (2.0 - 1.5 * f));
    vec2 w3 = f * f * (-0.5 + 0.5 * f);
    vec2 w12 = w1 + w2;
    vec2 at0 = (centre - 1.0) / size;
    vec2 at3 = (centre + 2.0) / size;
    vec2 at12 = (centre + w2 / w12) / size;
    vec3 sum = textureLod(colortex9, vec2(at12.x, at0.y), 0.0).rgb * w12.x * w0.y
             + textureLod(colortex9, vec2(at0.x, at12.y), 0.0).rgb * w0.x * w12.y
             + textureLod(colortex9, at12, 0.0).rgb * w12.x * w12.y
             + textureLod(colortex9, vec2(at3.x, at12.y), 0.0).rgb * w3.x * w12.y
             + textureLod(colortex9, vec2(at12.x, at3.y), 0.0).rgb * w12.x * w3.y;
    float weight = w12.x * w0.y + w0.x * w12.y + w12.x * w12.y + w3.x * w12.y + w12.x * w3.y;
    return max(sum / weight, vec3(0.0));
}

void main() {
    mx_setup();
    ivec2 texel = ivec2(gl_FragCoord.xy);
    vec3 current = current_at(texel);

    // The colors around the pixel, as a mean and spread, and the nearest depth among them: along an edge the
    // nearer thing is the one whose movement the edge follows.
    vec3 mean = vec3(0.0);
    vec3 square = vec3(0.0);
    float nearest = 1.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            ivec2 at = texel + ivec2(x, y);
            vec3 c = to_ycocg(current_at(at));
            mean += c;
            square += c * c;
            nearest = min(nearest, texelFetch(depthtex0, clamp(at, ivec2(0), ivec2(MxScreen.xy) - 1), 0).r);
        }
    }
    mean /= 9.0;
    vec3 spread = sqrt(max(square / 9.0 - mean * mean, vec3(0.0)));

    vec2 last = last_frame_uv(texCoord, nearest);
    bool seen = all(greaterThanEqual(last, vec2(0.0))) && all(lessThanEqual(last, vec2(1.0)));

    vec3 result = current;
    if (seen) {
        // Pulled towards the mean until it lies within the spread of the colors here.
        vec3 earlier = to_ycocg(history_at(last));
        vec3 reach = spread * 1.25 + 1.0e-4;
        vec3 off = (earlier - mean) / reach;
        float furthest = max(abs(off.x), max(abs(off.y), abs(off.z)));
        if (furthest > 1.0) {
            earlier = mean + (earlier - mean) / furthest;
        }
        // Mostly the earlier frames; more of this one while moving fast, when what came before is smeared
        // across the pixels it passed.
        float moved = length((last - texCoord) * MxScreen.xy);
        float share = mix(0.1, 0.3, clamp(moved / 16.0, 0.0, 1.0));
        result = from_ycocg(mix(earlier, to_ycocg(current), share));
    }

    fragColor = vec4(result, 1.0);
    history = vec4(result, 1.0);
}
