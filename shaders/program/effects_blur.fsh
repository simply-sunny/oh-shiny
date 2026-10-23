// Softens the half-size effects image without smearing across depth edges.

uniform sampler2D colortex6;
uniform sampler2D colortex15;

in vec2 texCoord;

layout(location = 0) out vec4 fragColor;

void main() {
    ivec2 size = textureSize(colortex6, 0);
    ivec2 pixel = ivec2(gl_FragCoord.xy);
    float here = texelFetch(colortex15, pixel, 0).r;
    vec4 sum = vec4(0.0);
    float weights = 0.0;
    for (int y = -2; y <= 2; y++) {
        for (int x = -2; x <= 2; x++) {
            ivec2 at = clamp(pixel + ivec2(x, y), ivec2(0), size - 1);
            float there = texelFetch(colortex15, at, 0).r;
            float weight = exp(-abs(there - here) / (0.03 * here + 0.15)) * exp(-float(x * x + y * y) * 0.15);
            sum += texelFetch(colortex6, at, 0) * weight;
            weights += weight;
        }
    }
    fragColor = sum / max(weights, 1.0e-4);
}
