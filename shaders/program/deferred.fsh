// After solid things and before water and glass: a copy of the picture so far, which water reflects and refracts.

/*
const int colortex0Format = RGBA16;
const int colortex5Format = RGBA16;
const int colortex6Format = RGBA16F;
const int colortex7Format = RGBA16F;
const int colortex10Format = RGBA16F;
const int colortex11Format = RGBA16F;
const int colortex12Format = RGBA16F;
const int colortex13Format = RGBA16F;
const int colortex14Format = RGBA16F;
const int colortex15Format = R32F;
*/
const bool colortex5Clear = false;

uniform sampler2D colortex0;

in vec2 texCoord;

layout(location = 0) out vec4 sceneCopy;

void main() {
    sceneCopy = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0);
}
