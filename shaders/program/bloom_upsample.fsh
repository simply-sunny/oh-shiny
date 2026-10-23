// One step up the glow's chain: grows the smaller MX_BLOOM_IN back up with a 3x3 tent and adds it onto
// MX_BLOOM_OUT, the size above it, which is also the image written. The stage file names both.

in vec2 texCoord;

layout(location = 0) out vec4 fragColor;

void main() {
    vec2 texel = 1.0 / vec2(textureSize(MX_BLOOM_IN, 0));
    vec3 sum = texture(MX_BLOOM_IN, texCoord).rgb * 4.0;
    sum += texture(MX_BLOOM_IN, texCoord + texel * vec2(-1.0, 0.0)).rgb * 2.0;
    sum += texture(MX_BLOOM_IN, texCoord + texel * vec2(1.0, 0.0)).rgb * 2.0;
    sum += texture(MX_BLOOM_IN, texCoord + texel * vec2(0.0, -1.0)).rgb * 2.0;
    sum += texture(MX_BLOOM_IN, texCoord + texel * vec2(0.0, 1.0)).rgb * 2.0;
    sum += texture(MX_BLOOM_IN, texCoord + texel * vec2(-1.0, -1.0)).rgb;
    sum += texture(MX_BLOOM_IN, texCoord + texel * vec2(1.0, -1.0)).rgb;
    sum += texture(MX_BLOOM_IN, texCoord + texel * vec2(-1.0, 1.0)).rgb;
    sum += texture(MX_BLOOM_IN, texCoord + texel * vec2(1.0, 1.0)).rgb;
    vec3 here = texelFetch(MX_BLOOM_OUT, ivec2(gl_FragCoord.xy), 0).rgb;
    fragColor = vec4(here + sum / 16.0, 1.0);
}
