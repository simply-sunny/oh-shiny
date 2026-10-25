#ifndef MX_NOISE
#define MX_NOISE

// Cheap noise, shared by water, caustics and anything else that needs some randomness.

float mx_hash(vec2 cell) {
    return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

// Smooth noise, 0..1: a random value at each whole coordinate, blended in between.
float mx_noise(vec2 point) {
    vec2 cell = floor(point);
    vec2 blend = fract(point);
    blend = blend * blend * (3.0 - 2.0 * blend);
    return mix(mix(mx_hash(cell), mx_hash(cell + vec2(1.0, 0.0)), blend.x),
               mix(mx_hash(cell + vec2(0.0, 1.0)), mx_hash(cell + vec2(1.0, 1.0)), blend.x), blend.y);
}

// mx_noise's slope at a point, worked out from the same four values rather than from more lookups of it.
vec2 mx_noise_slope(vec2 point) {
    vec2 cell = floor(point);
    vec2 f = fract(point);
    vec2 blend = f * f * (3.0 - 2.0 * f);
    vec2 rate = 6.0 * f * (1.0 - f);
    float a = mx_hash(cell);
    float b = mx_hash(cell + vec2(1.0, 0.0));
    float c = mx_hash(cell + vec2(0.0, 1.0));
    float d = mx_hash(cell + vec2(1.0, 1.0));
    float twist = a - b - c + d;
    return rate * vec2(b - a + twist * blend.y, c - a + twist * blend.x);
}

float mx_dither(vec2 pixel) {
    return fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));
}

#endif
