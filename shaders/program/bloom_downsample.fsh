// One step down the glow's chain: halves MX_BLOOM_IN again, the center plus four diagonal samples, each of
// which already averages four texels. The stage file names the image read and the one written.

in vec2 texCoord;

layout(location = 0) out vec4 fragColor;

void main() {
    vec2 texel = 1.0 / vec2(textureSize(MX_BLOOM_IN, 0));
    vec3 sum = texture(MX_BLOOM_IN, texCoord).rgb * 4.0;
    sum += texture(MX_BLOOM_IN, texCoord + texel * vec2(-1.0, -1.0)).rgb;
    sum += texture(MX_BLOOM_IN, texCoord + texel * vec2(1.0, -1.0)).rgb;
    sum += texture(MX_BLOOM_IN, texCoord + texel * vec2(-1.0, 1.0)).rgb;
    sum += texture(MX_BLOOM_IN, texCoord + texel * vec2(1.0, 1.0)).rgb;
    fragColor = vec4(sum / 8.0, 1.0);
}
